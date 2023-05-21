module Abstractor
  module Abstractable
    # @!parse include Abstractor::Abstractable::InstanceMethods
    # @!parse extend Abstractor::Abstractable::ClassMethods
    def self.included(base)
      base.class_eval do
        has_many :abstractor_abstractions, class_name: 'Abstractor::AbstractorAbstraction', as: :about

        has_many :abstractor_abstraction_groups, class_name: 'Abstractor::AbstractorAbstractionGroup', as: :about

        accepts_nested_attributes_for :abstractor_abstractions, allow_destroy: false
      end
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
    end

    module InstanceMethods
      ##
      # Whether or not the abstrabable entity 'fully set'.  Every non-deleted abstraction has a non-blank value.
      #
      # @return [Boolean]
      def fully_set?
        !abstractor_abstractions.not_deleted.any? { |abstractor_abstraction| abstractor_abstraction.value.blank?  }
      end

      ##
      # Whether or not the abstrabable entity has a 'submitted' workflow status.  Every non-deleted abstraction must be 'submitted'.
      #
      # @return [Boolean]
      def submitted?
        !abstractor_abstractions.not_deleted.any? { |abstractor_abstraction| !abstractor_abstraction.submitted? }
      end

      ##
      # Whether or not the abstrabable entity has a 'discarded' workflow status.  Every non-deleted abstraction must be 'discarded'.
      #
      # @return [Boolean]
      def discarded?
        !abstractor_abstractions.not_deleted.any? { |abstractor_abstraction| !abstractor_abstraction.discarded? }
      end

      ##
      # Returns all suggestion sources for the abstractable entity.
      #
      # @param [Hash] options the options to filter the list of suggstion sources to a namespace.
      # @option options [String] :namespace_type The type parameter of the namespace.
      # @option options [Integer] :namespace_id The instance parameter of the namespace.
      # @return [ActiveRecord::Relation] List of [Abstractor::AbstractorSuggestionSource].
      def abstractor_suggestion_sources(options = {})
        options = { namespace_type: nil, namespace_id: nil }.merge(options)
        abstractor_suggestion_sources = []
        abstractor_abstractions_by_namespace(options).each do |abstractor_abstraction|
          abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
            if abstractor_suggestion.abstractor_suggestion_sources.any?
              abstractor_suggestion_sources.concat(abstractor_suggestion.abstractor_suggestion_sources)
            end
          end
        end

        abstractor_suggestion_sources = abstractor_suggestion_sources.compact
        abstractor_suggestion_sources
      end

      ##
      # Returns all sources for the abstractable entity.  The method provides a higher-level view across
      # an abstractable entity's abstractions: a of list of textual sources mapped to the sentence matches contained therin.
      #
      # @param [Hash] options the options to filter the list of abstractions to a namespace.
      # @option options [String] :namespace_type The type parameter of the namespace.
      # @option options [Integer] :namespace_id The instance parameter of the namespace.
      # @return [Array] List of [Hash].
      def sources(options = {})
        options = { namespace_type: nil, namespace_id: nil }.merge(options)
        sources = abstractor_suggestion_sources(options).map { |abstractor_suggestion_source| { source_type: abstractor_suggestion_source.source_type.constantize, source_id: abstractor_suggestion_source.source_id, source_method: abstractor_suggestion_source.source_method } }.uniq
        sources.each do |source|
          source[:abstractor_suggestion_sources] = abstractor_suggestion_sources.select do |abstractor_suggestion_source|
            source[:source_type] == abstractor_suggestion_source.source_type.constantize &&
            source[:source_id] == abstractor_suggestion_source.source_id &&
            source[:source_method] == abstractor_suggestion_source.source_method
            # source[:section_name] == abstractor_suggestion_source.section_name
          end.map do |abstractor_suggestion_source|
            {
              source_type: abstractor_suggestion_source.source_type.constantize,
              source_id: abstractor_suggestion_source.source_id,
              source_method: abstractor_suggestion_source.source_method,
              # section_name: abstractor_suggestion_source.section_name,
              sentence_match_value: abstractor_suggestion_source.sentence_match_value
            }
          end.uniq
        end
        sources
      end

      ##
      # Returns all abstractions for the abstractable entity by a namespace.
      #
      # @param [Hash] options the options to filter the list of abstractions to a namespace.
      # @option options [String] :namespace_type The type parameter of the namespace.
      # @option options [Integer] :namespace_id The instance parameter of the namespace.
      # @return [ActiveRecord::Relation] List of [Abstractor::AbstractorAbstraction].
      def abstractor_abstractions_by_namespace(options = {})
        options = { namespace_type: nil, namespace_id: nil }.merge(options)
        abstractions = abstractor_abstractions.not_deleted
        if options[:namespace_type] || options[:namespace_id]
          abstractions = abstractions.where(abstractor_subject_id: self.class.abstractor_subjects(options).map(&:id))
        end
        abstractions
      end

      ##
      # Returns all abstractions for the abstractable entity by abstraction options.
      #
      # @param [Hash] options the options to filter the list of abstractions to a namespace.
      # @option options [Array] :abstractor_abstraction_schema_ids List of [Abstractor::AbstractorAbstractionSchema] ids
      # @option options [Abstractor::AbstractorAbstraction] :abstractor_abstraction_group Instance of an abstraction group.
      # @return [ActiveRecord::Relation] List of [Abstractor::AbstractorAbstraction].
      def abstractor_abstractions_by_abstraction_schemas(options = {})
        options = { abstractor_abstraction_schema_ids: [], abstractor_abstractions: abstractor_abstractions.not_deleted, abstractor_abstraction_group: nil }.merge(options)
        if options[:abstractor_abstraction_schema_ids].any?
          abstractions = options[:abstractor_abstractions].joins(:abstractor_subject).where(abstractor_subjects: { abstractor_abstraction_schema_id: options[:abstractor_abstraction_schema_ids]})
        else
          abstractions = options[:abstractor_abstractions]
        end

        if options[:abstractor_abstraction_group]
          abstractions.to_a.reject! { |abstraction| abstraction.abstractor_abstraction_group !=  options[:abstractor_abstraction_group]  }
        end
        abstractions
      end

      ##
      # Returns all abstraction groups for the abstractable entity by a namespace.
      #
      # @param [Hash] options the options to filter the list of abstraction groups to a namespace.
      # @option options [String] :namespace_type The type parameter of the namespace.
      # @option options [Integer] :namespace_id The instance parameter of the namespace.
      # @return [ActiveRecord::Relation] List of [Abstractor::AbstractorAbstractionGroup].
      def abstractor_abstraction_groups_by_namespace(options = {})
        options = { namespace_type: nil, namespace_id: nil }.merge(options)
        if options[:namespace_type] || options[:namespace_id]
          groups = abstractor_abstraction_groups.find(abstractor_abstractions_by_namespace(options).joins(:abstractor_abstraction_group).includes(:abstractor_abstraction_group).order('abstractor_abstraction_groups.id ASC').map{|s| s.abstractor_abstraction_group.id })
        else
          groups = abstractor_abstraction_groups.not_deleted.order('id ASC')
        end
        if options[:abstractor_subject_group_id]
          groups.select{|g| g.abstractor_subject_group_id == options[:abstractor_subject_group_id]}
        else
          groups
        end
      end

      ##
      # The method for generating abstractions from the abstractable entity.
      #
      # The generation of abstactions is based on the setup of Abstactor::AbstractorAbstactionSchema,
      # Abstractor::AbstractorSubject, Abstractor::AbstractorSubjectGroup and Abstractor::AbstractorAbstractionSource associated to the abstractable entity.
      #
      # Namespacing allows for different sets data points to be associated to the same abstractable entity.
      #
      # Namespacing is achieved by setting the Abstractor::AbstractorSubject#namespace_type and Abstractor::AbstractorSubject#namespace_id attributes.
      #
      # Passing a namespace to this method will restrict the generation of abstractions to the given namespace. Otherwise, all configured abstractions associated to the abstractable entity will be generated.
      #
      # A practical example of the use of a namespace would be two different clincal departments wanting to chart abstract two distinct sets of datapoints for progress notes extracted from an electronic medical record system.
      # @param [Hash] options the options to filter the generation of abstractions to a namespace.
      # @option options [String] :namespace_type The type parameter of the namespace.
      # @option options [Integer] :namespace_id The instance parameter of the namespace.
      # @option options [List of integers] :abstractor_abstraction_schema_ids List of abstractor_abstraction_schema_ids to limit abstraction.
      # @return [void]
      def abstract(options = {})
        options = { namespace_type: nil, namespace_id: nil, abstractor_abstraction_schema_ids: [] }.merge(options)
        sentential_groups = []
        self.class.abstractor_subjects(options).each do |abstractor_subject|
          abstractor_subject.abstract(self)
          sentential_groups << abstractor_subject.abstractor_subject_group if abstractor_subject.abstractor_subject_group && abstractor_subject.abstractor_subject_group.has_subtype?(Abstractor::Enum::ABSTRACTOR_GROUP_SENTENTIAL_SUBTYPE)
        end
        sentential_groups.uniq.map{|sentential_group| regroup_sentential_suggestions(sentential_group, options)}
      end

      def abstract_multiple(options = {})
        options = { namespace_type: nil, namespace_id: nil, abstractor_abstraction_schema_ids: [] }.merge(options)
        sources_with_abstractor_abstraction_schemas = []
        # puts 'begin abstraction creation timing'
        # start = Time.now
        self.class.abstractor_subjects(options).each do |abstractor_subject|
          # puts 'begin individual abstraction creation timing'
          # start = Time.now
          abstractor_abstraction = self.find_or_create_abstractor_abstraction(abstractor_subject.abstractor_abstraction_schema, abstractor_subject)
          # finish = Time.now
          # diff = finish - start
          # puts 'how long did you take?'
          # puts diff
          # puts 'end individual  abstraction creation timing'

          # puts 'begin sources timing'
          # start = Time.now
          abstractor_subject.abstractor_abstraction_sources.each do |abstractor_abstraction_source|
            abstractor_abstraction_source.normalize_from_method_to_sources(self).each do |source|
              if s = sources_with_abstractor_abstraction_schemas.detect { |s| s[:source] == source }
                s[:abstractor_abstraction_schemas] << abstractor_subject.abstractor_abstraction_schema
                if !s[:abstractor_abstraction_sources].detect { |aas| aas == abstractor_abstraction_source }
                  s[:abstractor_abstraction_sources] << abstractor_abstraction_source
                end
                if !s[:abstractor_abstractions].detect { |a| a ==  abstractor_abstraction }
                  s[:abstractor_abstractions] << abstractor_abstraction
                end
              else
                sources_with_abstractor_abstraction_schemas << { source: source, abstractor_abstraction_sources: [abstractor_abstraction_source], abstractor_abstractions: [abstractor_abstraction], abstractor_abstraction_schemas: [abstractor_subject.abstractor_abstraction_schema] }
              end
            end
          end
          # finish = Time.now
          # diff = finish - start
          # puts 'how long did you take?'
          # puts diff
          # puts 'end sources timing'
        end
        # finish = Time.now
        # diff = finish - start
        # puts 'how long did you take?'
        # puts diff
        # puts 'end abstraction creation timing'

        body = nil
        sources_with_abstractor_abstraction_schemas.each do |source_with_abstractor_abstraction_schema|
          abstractor_text = Abstractor::AbstractorAbstractionSource.abstractor_text(source_with_abstractor_abstraction_schema[:source])
          body = Abstractor::CustomNlpProvider.format_body_for_multiple_suggestion_endpoint(source_with_abstractor_abstraction_schema[:abstractor_abstractions], source_with_abstractor_abstraction_schema[:abstractor_abstraction_sources], abstractor_text, source_with_abstractor_abstraction_schema[:source], options[:namespace_type], options[:namespace_id])
          custom_nlp_providers = source_with_abstractor_abstraction_schema[:abstractor_abstraction_sources].map(&:custom_nlp_provider).uniq
          custom_nlp_providers.each do |custom_nlp_provider|
            multiple_suggestion_endpoint = Abstractor::CustomNlpProvider.determine_multiple_suggestion_endpoint(custom_nlp_provider)
            if multiple_suggestion_endpoint.present?
              suggestion_endpoint_auth = Abstractor::CustomNlpProvider.determine_suggestion_endpoint_credentials(custom_nlp_provider).symbolize_keys

              if !Rails.env.test?
                user = User.where(username: suggestion_endpoint_auth[:username]).first
                # suggestion_endpoint_auth[:password] = user.authentication_token
                suggestion_endpoint_auth[:password] = 'password'
              end
              # puts 'suggestion_endpoint'
              # puts multiple_suggestion_endpoint
              # puts 'body'
              # puts body.to_json
              # puts 'here we go again'

              # puts 'begin post timing'
              # start = Time.now
              result = HTTParty.post(multiple_suggestion_endpoint, { body: body.to_json, headers: { 'Content-Type' => 'application/json', }, basic_auth: suggestion_endpoint_auth, :debug_output => $stdout })
              # finish = Time.now
              # diff = finish - start
              # puts 'how long did you take?'
              # puts diff
              # puts 'end post timing'
            else
              puts 'multiple_suggestion_endpoint is not present'
            end

            multiple_suggestion_file_location = Abstractor::CustomNlpProvider.determine_multiple_suggestion_file_location(custom_nlp_provider)
            if multiple_suggestion_file_location.present?
              # puts 'begin file timing'
              # start = Time.now
              # puts 'suggestion_endpoint'
              # puts multiple_suggestion_file_location
              # puts 'body'
              # puts body
              # puts 'here we go again'

              File.open "#{multiple_suggestion_file_location}/#{source_with_abstractor_abstraction_schema[:source][:source_type]}_#{source_with_abstractor_abstraction_schema[:source][:source_id]}_#{Time.now.to_i}.json", 'w' do |f|
                f.puts body.to_json
              end
              # finish = Time.now
              # diff = finish - start
              # puts 'how long did you take?'
              # puts diff
              # puts 'end file timing'
            end
          end
        end
      end

      def detect_abstractor_abstraction(abstractor_subject)
        abstractor_abstractions.reload.not_deleted.detect { |abstractor_abstraction| abstractor_abstraction.abstractor_subject_id == abstractor_subject.id }
      end

      def find_or_create_abstractor_abstraction(abstractor_abstraction_schema, abstractor_subject)
        options = { namespace_type: abstractor_subject.namespace_type, namespace_id: abstractor_subject.namespace_id }
        if abstractor_abstraction = detect_abstractor_abstraction(abstractor_subject)
        else
          abstractor_abstraction = Abstractor::AbstractorAbstraction.create!(abstractor_subject: abstractor_subject, about: self, workflow_status: Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING)

          if abstractor_subject.groupable?
            abstractor_abstraction_group = find_or_initialize_abstractor_abstraction_group(abstractor_subject.abstractor_subject_group, options)
            abstractor_abstraction_group.abstractor_abstractions << abstractor_abstraction
            abstractor_abstraction_group.save!
          end
        end
        abstractor_abstraction
      end

      def detect_abstractor_abstraction_group(abstractor_subject_group, options)
        abstractor_abstraction_groups.reload.
          select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group_id ==  abstractor_subject_group.id }.
          select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.joins(:abstractor_subject).where(abstractor_subjects: { namespace_type: options[:namespace_type], namespace_id: options[:namespace_id]}).any?}.
          first
      end

      def find_or_initialize_abstractor_abstraction_group(abstractor_subject_group, options)
        if abstractor_abstraction_group = detect_abstractor_abstraction_group(abstractor_subject_group, options)
        else
          abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group: abstractor_subject_group, about: self, system_generated: true)
        end
        abstractor_abstraction_group
      end

      ##
      # Determines if provided abstractor_subject_group reached number of abstractor_abstraction_groups defined by abstractor_subject_group cardinality
      #
      # @param [Integer] abstractor_subject_group_id the id of abstractor_subject_group of interest.
      # @option options [String]  :namespace_type the type parameter of the namespace.
      # @option options [Integer] :namespace_id the instance parameter of the namespace.
      # @return [Boolean]
      def abstractor_subject_group_complete?(abstractor_subject_group_id, options = {})
        abstractor_subject_group = Abstractor::AbstractorSubjectGroup.find(abstractor_subject_group_id)
        if abstractor_subject_group.cardinality.blank?
          false
        else
          options = { namespace_type: nil, namespace_id: nil, abstractor_subject_group_id: abstractor_subject_group_id }.merge(options)
          abstractor_abstraction_groups = abstractor_abstraction_groups_by_namespace(options)
          abstractor_abstraction_groups.length == abstractor_subject_group.cardinality
        end
      end

      ##
      # Returns all abstraction for the abstractable entity by abstractor_abstraction_status:
      #
      # * 'needs_review': Filter abstractions without a determined value (value, unknown or not_applicable).
      # * 'reviewed': Filter abstractions having a determined value (value, unknown or not_applicable).
      #
      # @param [String] abstractor_abstraction_status Filter abstractions that need review or are reviews.
      # @param [Hash] options the options to filter abstractions to a namespace.
      # @option options [String] :namespace_type the type parameter of the namespace.
      # @option options [Integer] :namespace_id the instance parameter of the namespace.
      # @return [ActiveRecord::Relation] list of [Abstractor::AbstractorAbstraction].
      def abstractor_abstractions_by_abstractor_abstraction_status(abstractor_abstraction_status, options = {})
        options = { namespace_type: nil, namespace_id: nil }.merge(options)
        case abstractor_abstraction_status
        when Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW
          abstractor_abstractions_by_namespace(options).select { |abstractor_abstraction| abstractor_abstraction.value.blank? && abstractor_abstraction.unknown.blank? && abstractor_abstraction.not_applicable.blank? }
        when Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED
          abstractor_abstractions_by_namespace(options).select { |abstractor_abstraction| !abstractor_abstraction.value.blank? || !abstractor_abstraction.unknown.blank? || !abstractor_abstraction.not_applicable.blank? }
        end
      end

      ##
      # Removes all abstractions, suggestions and indirect sources for the abstractable entity.  Optionally filtred to only 'unreviewed' abstractions and to a given namespace.
      #
      # @param [Hash] options the options to filter the removal of abstractions.
      # @option options [Booelan] :only_unreviewed Instructs whether to confine removal to only 'unreviewed' abstractions.
      # @option options [String] :namespace_type The type parameter of the namespace to remove.
      # @option options [Integer] :namespace_id The instance parameter of the namespace to remove.
      # @option options [List of integers] :abstractor_abstraction_schema_ids List of abstractor_abstraction_schema_ids to limit abstraction removal.
      # @return [void]
      def remove_abstractions(options = {})
        options = { only_unreviewed: true, namespace_type: nil, namespace_id: nil, abstractor_abstraction_schema_ids: [] }.merge(options)
        abstractor_abstractions = abstractor_abstractions_by_namespace(options)
        if options[:abstractor_abstraction_schema_ids].any?
          options = { abstractor_abstractions: abstractor_abstractions }.merge(options)
          abstractor_abstractions = abstractor_abstractions_by_abstraction_schemas(options)
        end
        abstractor_abstractions.each do |abstractor_abstraction|
          if !options[:only_unreviewed] || (options[:only_unreviewed] && abstractor_abstraction.unreviewed?)
            abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
              abstractor_suggestion.abstractor_suggestion_sources.destroy_all
              abstractor_suggestion.abstractor_suggestion_object_value.destroy if abstractor_suggestion.abstractor_suggestion_object_value
              abstractor_suggestion.destroy
            end
            abstractor_abstraction.abstractor_indirect_sources.each do |abstractor_indirect_source|
              abstractor_indirect_source.destroy
            end
            abstractor_abstraction.destroy
          end
        end
      end

      ##
      # Regroups suggestions for subjects grouped marked with 'sentential' subtype. Does not affect abstraction groups with curated values.
      # Creates an abstraction group for each combination of suggestions that came from the same sentence.
      # Creates groups only if there are enough abstractions.
      #
      # @param [ActiveRecord::Relation] sentential_group sentential group to process
      # @return [void]
      def regroup_sentential_suggestions(sentential_group, options)
        sentential_group_abstractor_subjects           = sentential_group.abstractor_subjects.not_deleted
        if options[:namespace_type] || options[:namespace_id]
          sentential_group_abstractor_subjects           = sentential_group_abstractor_subjects.where(namespace_type: options[:namespace_type], namespace_id: options[:namespace_id])
        end

        sentential_group_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.not_deleted.joins(:abstractor_subject_group, :abstractor_abstractions).where(abstractor_subject_group_id: sentential_group.id, abstractor_abstractions: {about_id: self.id, abstractor_subject_id: sentential_group_abstractor_subjects.map(&:id)}).distinct

        sentential_group_abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
          .where(abstractor_abstraction_groups: { id: sentential_group_abstractor_abstraction_groups.map(&:id)}, abstractor_abstractions: { abstractor_subject_id: sentential_group_abstractor_subjects.map(&:id), about_id: self.id})

        sentential_abstractor_abstraction_groups = sentential_group_abstractor_abstraction_groups.where(subtype: Abstractor::Enum::ABSTRACTOR_GROUP_SENTENTIAL_SUBTYPE)

        sentential_group_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          unless abstractor_abstraction_group.abstractor_abstractions.not_deleted.where(about_id: self.id).where('value is not null').any? # skip abstraction groups with curated abstractions
            # get all suggestion sources
            abstractor_suggestion_sources = sentential_group_abstractor_suggestion_sources.where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id})

            # get all matched sentences
            sentence_match_values = abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).compact

            # skip groups where all abstractions come from the same sentence
            unless sentence_match_values.length == 1
              # create abstraction group for each sentence
              sentence_match_values.each do |sentence_match_value|
                # get all suggestion sources that reference the sentence
                abstractor_suggestion_sources_by_sentence = abstractor_suggestion_sources.where(sentence_match_value: sentence_match_value)

                abstractor_subjects = abstractor_suggestion_sources_by_sentence.
                  map{|abstractor_suggestion_source| abstractor_suggestion_source.abstractor_suggestion.abstractor_abstraction.abstractor_subject }.
                  reject{|abstractor_subject| abstractor_subject.abstractor_subject_group.blank? || abstractor_subject.abstractor_subject_group.id != sentential_group.id}.uniq

                if abstractor_subjects.length == sentential_group_abstractor_subjects.length
                  matching_abstractor_suggestion_sources = sentential_group_abstractor_suggestion_sources.where(sentence_match_value: sentence_match_value)

                  existing_abstractor_abstraction_group = matching_abstractor_suggestion_sources.
                    map{|abstractor_suggestion_source| abstractor_suggestion_source.abstractor_suggestion.abstractor_abstraction.abstractor_abstraction_group}.
                    select{|aag| sentential_abstractor_abstraction_groups.map(&:id).include? aag.id}.
                    reject{|aag| aag.id == abstractor_abstraction_group.id}.uniq.first

                  if existing_abstractor_abstraction_group
                    new_abstractor_abstraction_group = existing_abstractor_abstraction_group
                  else
                    new_abstractor_abstraction_group  = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group: abstractor_abstraction_group.abstractor_subject_group, about: self, system_generated: true, subtype: abstractor_abstraction_group.abstractor_subject_group.subtype)
                  end

                  abstractor_suggestion_sources_by_sentence.all.each do |abstractor_suggestion_source|
                    abstractor_suggestion   = abstractor_suggestion_source.abstractor_suggestion
                    abstractor_abstraction  = abstractor_suggestion.abstractor_abstraction

                    # if corresponding abstraction has more than one suggestion and should not be moved
                    # create a new abstraction if the new group does not yet have abstraction for the same subject
                    abstractor_subject = abstractor_abstraction.abstractor_subject
                    existing_new_abstractor_abstraction = new_abstractor_abstraction_group.abstractor_abstractions.select{|aa| aa.abstractor_subject_id == abstractor_subject.id}.first

                    if existing_new_abstractor_abstraction
                      new_abstractor_abstraction = existing_new_abstractor_abstraction
                    else
                      if abstractor_abstraction.abstractor_suggestions.length > 1
                        new_abstractor_abstraction  = Abstractor::AbstractorAbstraction.create!(abstractor_subject: abstractor_suggestion.abstractor_abstraction.abstractor_subject, about: self)
                      else
                        new_abstractor_abstraction = abstractor_abstraction
                        new_abstractor_abstraction.abstractor_abstraction_group_member = nil
                        new_abstractor_abstraction.build_abstractor_abstraction_group_member(abstractor_abstraction_group: new_abstractor_abstraction_group)
                      end
                      unless new_abstractor_abstraction_group.abstractor_abstractions.include? new_abstractor_abstraction
                        new_abstractor_abstraction_group.abstractor_abstractions << new_abstractor_abstraction
                      end
                    end

                    # if new abstraction already has matching suggestion, use it to map sources
                    new_abstractor_suggestion = new_abstractor_abstraction.detect_abstractor_suggestion(abstractor_suggestion.suggested_value, abstractor_suggestion.unknown, abstractor_suggestion.not_applicable)

                    # if matching suggestion does not exist, create a new suggestion if corresponding suggestion has multiple sources
                    # and should not be moved of move existing one to the new abstraction
                    # and map suggestion source to the new suggestion
                    if new_abstractor_suggestion.blank?
                      if abstractor_suggestion.abstractor_suggestion_sources.length > 1
                        new_abstractor_suggestion ||=  Abstractor::AbstractorSuggestion.create!(
                          abstractor_abstraction: new_abstractor_abstraction,
                          accepted: nil,
                          suggested_value: abstractor_suggestion.suggested_value,
                          unknown: abstractor_suggestion.unknown,
                          not_applicable: abstractor_suggestion.not_applicable
                        )
                      else
                        new_abstractor_suggestion = abstractor_suggestion
                      end
                    end

                    new_abstractor_suggestion.abstractor_abstraction  = new_abstractor_abstraction
                    new_abstractor_suggestion.save!

                    existing_abstractor_suggestion_source = abstractor_suggestion.detect_abstractor_suggestion_source(abstractor_suggestion_source.abstractor_abstraction_source, abstractor_suggestion_source.sentence_match_value, abstractor_suggestion_source.source_id, abstractor_suggestion_source.source_type, abstractor_suggestion_source.source_method, abstractor_suggestion_source.section_name)

                    if existing_abstractor_suggestion_source && existing_abstractor_suggestion_source != abstractor_suggestion_source
                      abstractor_suggestion_source.delete
                    else
                      abstractor_suggestion_source.abstractor_suggestion = new_abstractor_suggestion
                      abstractor_suggestion_source.save!
                    end
                  end

                  # do not save group if it does not have abstractions
                  new_abstractor_abstraction_group.save! if new_abstractor_abstraction_group.abstractor_abstractions.any?
                end
              end

              abstractor_abstraction_group_siblings = AbstractorAbstractionGroup.not_deleted.joins(:abstractor_subject_group, :abstractor_abstractions).where(abstractor_subject_group_id: sentential_group.id, abstractor_abstractions: {about_id: self.id, abstractor_subject_id: sentential_group_abstractor_subjects.map(&:id)}).distinct

              if abstractor_abstraction_group_siblings.length > 1
                abstractor_abstraction_group.reload.abstractor_abstractions.each do |abstractor_abstraction|
                  abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
                    abstractor_suggestion.abstractor_suggestion_sources.delete_all
                    abstractor_suggestion.abstractor_suggestion_object_value.delete if abstractor_suggestion.abstractor_suggestion_object_value
                    abstractor_suggestion.delete
                  end
                  abstractor_abstraction.abstractor_indirect_sources.each do |abstractor_indirect_source|
                    abstractor_indirect_source.delete
                  end
                  abstractor_abstraction.delete
                end
                abstractor_abstraction_group.reload.abstractor_abstraction_group_members.map{|a| a.delete}
                abstractor_abstraction_group.delete
              end
            end
          end
        end
      end

      def abstractor_namespaces
        Abstractor::AbstractorNamespaceEvent.where("abstractor_namespace_events.eventable_type = ? AND abstractor_namespace_events.eventable_id = ?", self.class.to_s, self.id).map { |abstractor_namespace_event| abstractor_namespace_event.abstractor_namespace }
      end
    end

    module ClassMethods
      def missing_abstractor_namespace_event(abstractor_namespace_id)
        where(["NOT EXISTS(SELECT 1 FROM abstractor_namespace_events WHERE abstractor_namespace_events.eventable_type = ? AND abstractor_namespace_events.eventable_id = #{self.table_name}.id AND abstractor_namespace_events.abstractor_namespace_id = ?)", self.to_s, abstractor_namespace_id])
      end
      ##
      # Returns a list of users who have updated the workflow status of the abstracrtable entity.
      #
      # @param [Hash] options The options to filter the entities returned.
      # @option options [String] :namespace_type The type parameter of the namespace to filter the entities.
      # @option options [Integer] :namespace_id The instance parameter of the namespace to filter the entities.
      # @return [String] List of users who have updated the workflow status of the abstractabe entity.
      def workflow_status_whodunnit_list(options = {})
        options = { namespace_type: nil, namespace_id: nil }.merge(options)
        if options[:namespace_type] || options[:namespace_id]
          Abstractor::AbstractorAbstraction.joins(:abstractor_subject).where(about_type: self.to_s, abstractor_subject: { namespace_type: options[:namespace_type], namespace_id: options[:namespace_id]}).where.not(workflow_status_whodunnit: nil).select('DISTINCT workflow_status_whodunnit')
        else
          Abstractor::AbstractorAbstraction.where(about_type: self.to_s).where.not(workflow_status_whodunnit: nil).select('DISTINCT workflow_status_whodunnit').all.map(&:workflow_status_whodunnit).sort
        end
      end
      ##
      # Returns all abstractable entities filtered by the parameter abstraction_workflow_status:
      #
      # * 'pending': Filter abstractable entites having at least one abstraction with a workflow status of of 'pending'
      # * 'submitted': Filter abstractable entites having all abstractions with a workflow status of 'submitted'
      # * 'discarded': Filter abstractable entites having all abstractions with a workflow status of 'discarded'
      # * 'submitted or discarded': Filter abstractable entites having all abstractions with a workflow status of either 'submitted' or  'discarded'
      #
      # @param [String] abstraction_workflow_status Filter abstactable entities based on abstraction workflow status.
      # @param [Hash] options The options to filter the entities returned.
      # @option options [String] :namespace_type The type parameter of the namespace to filter the entities.
      # @option options [Integer] :namespace_id The instance parameter of the namespace to filter the entities.
      # @return [ActiveRecord::Relation] List of abstractable entities.
      def by_abstraction_workflow_status(abstraction_workflow_status, options = {})
        options = { namespace_type: nil, namespace_id: nil, workflow_status_whodunnit: nil }.merge(options)
        if options[:namespace_type] || options[:namespace_id]
          case abstraction_workflow_status
          when Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND aa.workflow_status = ?)", options[:namespace_type], options[:namespace_id], Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING])
          when Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND aa.workflow_status = ? AND COALESCE(aa.workflow_status_whodunnit, '') = case when ? IS NULL THEN COALESCE(aa.workflow_status_whodunnit, '') ELSE ? END)", options[:namespace_type], options[:namespace_id], Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED, options[:workflow_status_whodunnit], options[:workflow_status_whodunnit]])
          when Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND aa.workflow_status = ? AND COALESCE(aa.workflow_status_whodunnit, '') = case when ? IS NULL THEN COALESCE(aa.workflow_status_whodunnit, '') ELSE ? END)", options[:namespace_type], options[:namespace_id], Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED, options[:workflow_status_whodunnit], options[:workflow_status_whodunnit]])
          when Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED_OR_DISCARDED
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND aa.workflow_status IN(?) AND COALESCE(aa.workflow_status_whodunnit, '') = case when ? IS NULL THEN COALESCE(aa.workflow_status_whodunnit, '') ELSE ? END)", options[:namespace_type], options[:namespace_id], [Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED, Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED], options[:workflow_status_whodunnit], options[:workflow_status_whodunnit]])
          else
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND aa.workflow_status_whodunnit = COALESCE(?, workflow_status_whodunnit))", options[:namespace_type], options[:namespace_id], options[:workflow_status_whodunnit], options[:workflow_status_whodunnit]])
          end
        else
          case abstraction_workflow_status
          when Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND aa.workflow_status = ?)", Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING])
          when Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND aa.workflow_status = ? AND COALESCE(aa.workflow_status_whodunnit, '') = case when ? IS NULL THEN COALESCE(aa.workflow_status_whodunnit, '') ELSE ? END)", Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED, options[:workflow_status_whodunnit], options[:workflow_status_whodunnit]])
          when Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND aa.workflow_status = ? AND COALESCE(aa.workflow_status_whodunnit, '') = case when ? IS NULL THEN COALESCE(aa.workflow_status_whodunnit, '') ELSE ? END)", Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED, options[:workflow_status_whodunnit], options[:workflow_status_whodunnit]])
          when Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED_OR_DISCARDED
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND aa.workflow_status IN(?)  AND COALESCE(aa.workflow_status_whodunnit, '') = case when ? IS NULL THEN COALESCE(aa.workflow_status_whodunnit, '') ELSE ? END)", [Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED, Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED], options[:workflow_status_whodunnit], options[:workflow_status_whodunnit]])
          else
            where(nil)
          end
        end
      end

      ##
      # Returns all abstractable entities filtered by the parameter abstractor_suggestion_type:
      #
      # * 'unknown': Filter abstractable entites having at least one suggestion with a suggested value of 'unknown'
      # * 'suggested': Filter abstractable entites having at least one suggestion with an actual value
      #
      # @param [String] abstractor_suggestion_type Filter abstactable entities that have a least one 'unknwon' or at least one 'suggested' suggestion
      # @param [Hash] options The options to filter the entities returned.
      # @option options [String] :namespace_type The type parameter of the namespace to filter the entities.
      # @option options [Integer] :namespace_id The instance parameter of the namespace to filter the entities.
      # @option options [List of Integer, List of ActiveRecord::Relation] :abstractor_abstraction_schemas The list of abstractor abstraction schemas to filter upon.  Defaults to all abstractor abstraction schemas if not specified.
      # @return [ActiveRecord::Relation] List of abstractable entities.
      def by_abstractor_suggestion_type(abstractor_suggestion_type, options = {})
        options = { namespace_type: nil, namespace_id: nil }.merge(options)
        options = { abstractor_abstraction_schemas: abstractor_abstraction_schemas }.merge(options)
        if options[:namespace_type] || options[:namespace_id]
          case abstractor_suggestion_type
          when Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id IN (?) JOIN abstractor_suggestions sug ON aa.id = sug.abstractor_abstraction_id JOIN abstractor_suggestion_sources src ON sug.id  = src.abstractor_suggestion_id WHERE sug.deleted_at IS NULL AND aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND sug.unknown = ?)", options[:namespace_type], options[:namespace_id], options[:abstractor_abstraction_schemas], true])
          when Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id IN (?) JOIN abstractor_suggestions sug ON aa.id = sug.abstractor_abstraction_id JOIN abstractor_suggestion_sources src ON sug.id  = src.abstractor_suggestion_id WHERE sug.deleted_at IS NULL AND aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND COALESCE(sug.unknown, ?) = ? AND sug.suggested_value IS NOT NULL AND COALESCE(sug.suggested_value, '') != '' )", options[:namespace_type], options[:namespace_id], options[:abstractor_abstraction_schemas], false, false])
          else
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? AND sub.abstractor_abstraction_schema_id IN (?) WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id)", options[:namespace_type], options[:namespace_id], options[:abstractor_abstraction_schemas]])
          end
        else
          case abstractor_suggestion_type
          when Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.abstractor_abstraction_schema_id IN (?) JOIN abstractor_suggestions sug ON aa.id = sug.abstractor_abstraction_id JOIN abstractor_suggestion_sources src ON sug.id  = src.abstractor_suggestion_id WHERE sug.deleted_at IS NULL AND aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND sug.unknown = ?)", options[:abstractor_abstraction_schemas], true])
          when Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.abstractor_abstraction_schema_id IN (?) JOIN abstractor_suggestions sug ON aa.id = sug.abstractor_abstraction_id JOIN abstractor_suggestion_sources src ON sug.id  = src.abstractor_suggestion_id WHERE sug.deleted_at IS NULL AND aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND COALESCE(sug.unknown, ?) = ? AND sug.suggested_value IS NOT NULL AND COALESCE(sug.suggested_value, '') != '' )", options[:abstractor_abstraction_schemas], false, false])
          else
            where(nil)
          end
        end
      end

      ##
      # Returns all abstractable entities filtered by the parameter abstractor_abstraction_status:
      #
      # * 'needs_review': Filter abstractable entites having at least one abstraction without a determined value (value, unknown or not_applicable).
      # * 'reviewed': Filter abstractable entites having no abstractions without a determined value (value, unknown or not_applicable).
      # * 'actually answered': Filter abstractable entites having no abstractions without an actual value (exluding blank, unknown or not_applicable).
      # @param [String] abstractor_abstraction_status Filter abstactable entities that an abstraction that 'needs_review' or are all abstractions are 'reviewed'.
      # @param [Hash] options the options to filter the entities returned.
      # @option options [String] :namespace_type The type parameter of the namespace to filter the entities.
      # @option options [Integer] :namespace_id The instance parameter of the namespace to filter the entities.
      # @return [ActiveRecord::Relation] List of abstractable entities.
      def by_abstractor_abstraction_status(abstractor_abstraction_status, options = {})
        options = { namespace_type: nil, namespace_id: nil }.merge(options)

        if options[:namespace_type] || options[:namespace_id]
          case abstractor_abstraction_status
          when Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id IN(?) WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND (aa.value IS NULL OR aa.value = '') AND (aa.unknown IS NULL OR aa.unknown = ?) AND (aa.not_applicable IS NULL OR aa.not_applicable = ?))", options[:namespace_type], options[:namespace_id], false, false])
          when Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id IN(?) WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id) AND NOT EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND COALESCE(aa.value, '') = '' AND COALESCE(aa.unknown, ?) != ? AND COALESCE(aa.not_applicable, ?) != ?)", options[:namespace_type], options[:namespace_id], options[:namespace_type], options[:namespace_id], false, true, false, true])
          # when Abstractor::Enum::ABSTRACTION_STATUS_ACTUALLY_ANSWERED
          #   where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id IN(?) WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id) AND NOT EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id = ? WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND COALESCE(aa.value, '') = '')", options[:namespace_type], options[:namespace_id], options[:namespace_type], options[:namespace_id]])
          else
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa JOIN abstractor_subjects sub ON aa.abstractor_subject_id = sub.id AND sub.namespace_type = ? AND sub.namespace_id IN(?) WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id)", options[:namespace_type], options[:namespace_id]])
          end
        else
          case abstractor_abstraction_status
          when Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND (aa.value IS NULL OR aa.value = '') AND (aa.unknown IS NULL OR aa.unknown = ?) AND (aa.not_applicable IS NULL OR aa.not_applicable = ?))", false, false])
          when Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED
            where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id) AND NOT EXISTS (SELECT 1 FROM abstractor_abstractions aa WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND COALESCE(aa.value, '') = '' AND COALESCE(aa.unknown, ?) != ? AND COALESCE(aa.not_applicable, ?) != ?)", false, true, false, true])
          # when Abstractor::Enum::ABSTRACTION_STATUS_ACTUALLY_ANSWERED
          #   where(["EXISTS (SELECT 1 FROM abstractor_abstractions aa WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id) AND NOT EXISTS (SELECT 1 FROM abstractor_abstractions aa WHERE aa.deleted_at IS NULL AND aa.about_type = '#{self.to_s}' AND #{self.table_name}.id = aa.about_id AND COALESCE(aa.value, '') = '')"])
          else
            where(nil)
          end
        end
      end

      ##
      # Returns the abstractor subjects associated with the abstractable entity.
      #
      # By default, the method will return all abstractor subjects.
      #
      # @param [Hash] options the options to filter the subjects returned.
      # @option options [Boolean] :grouped Filters the list of Abstactor::AbstractorSubject objects to grouped and non-grouped.  Defaults to nil which returns all objects.
      # @option options [String] :namespace_type The type parameter of the namespace to filter the subjects.
      # @option options [Integer] :namespace_id The instance parameter of the namespace to filter the subjects.
      # @return ActiveRecord::Relation list of Abstactor::AbstractorSubject objects
      def abstractor_subjects(options = {})
        options = { grouped: nil, namespace_type: nil, namespace_id: nil, abstractor_abstraction_schema_ids: [] }.merge(options)
        subjects = Abstractor::AbstractorSubject.where(subject_type: self.to_s)
        if options[:namespace_type] || options[:namespace_id]
          subjects = subjects.where(namespace_type: options[:namespace_type], namespace_id: options[:namespace_id])
        end

        if options[:abstractor_abstraction_schema_ids].any?
          subjects = subjects.where(abstractor_abstraction_schema_id: options[:abstractor_abstraction_schema_ids])
        end

        subjects = case options[:grouped]
        when true
          subjects.joins(:abstractor_subject_group).includes(:abstractor_subject_group)
        when false
          subjects.where("not exists (select 'a' from abstractor_subject_group_members where abstractor_subject_id = abstractor_subjects.id)")
        when nil
          subjects
        end
      end

      ##
      # Returns the abstractor abstraction schemas associated with the abstractable entity.
      #
      # By default, the method will return all abstractor abstraction schemas.
      #
      # @param [Hash] options the options to filter the abstaction schemas.
      # @option options [Boolean] :grouped Filters the list of Abstractor::AbstractorAbstractionSchema objects to grouped and non-grouped.  Defaults to nil which returns all abstraction schemas.
      # @option options [String] :namespace_type The type parameter of the namespace to filter the abstaction schemas.
      # @option options [Integer] :namespace_id The instance parameter of the namespace to filter the abstaction schemas.
      # @return ActiveRecord::Relation list of Abstactor::AbstractorAbstractionSchema objects
      def abstractor_abstraction_schemas(options = {})
        options = { grouped: nil, namespace_type: nil, namespace_id: nil }.merge(options)
        abstractor_subjects(options).map(&:abstractor_abstraction_schema)
      end

      def abstractor_subject_groups(options = {})
        options = { grouped: true, namespace_type: nil, namespace_id: nil }.merge(options)
        Abstractor::AbstractorSubjectGroup.find(abstractor_subjects(options).order(:created_at).map{|s| s.abstractor_subject_group.id})
      end

      ##
      # Pivot abstractions to simulate regular columns on an abstractable entity.
      #
      # Example: an ActiveRecod model PathologyCaseReport with the columns
      # * 'collection_date'
      # * 'report_text'
      # And the abstraction 'has_cancer_diagnosis'.
      #
      # This method allows for the querying of the pathology_cases table as if
      # it was strucutred like so:
      # 'select id, collection_date, report_text, has_cancer_diagnosis from pathology_cases'
      #
      # @param [Hash] options the options to pivot the abstractions.
      # @option options [String] :namespace_type The type parameter of the namespace to pivot abstractions.
      # @option options [Integer] :namespace_id The instance parameter of the namespace to pivot abstractions.
      # @return ActiveRecord::Relation
      def pivot_abstractions(options = {})
        options = { grouped: false, namespace_type: nil, namespace_id: nil }.merge(options)
        select = prepare_pivot_select(options)
        adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]
        j = case adapter
        when 'sqlite3'
          prepare_pivot_joins(select, "'1'", options)
        when 'sqlserver'
          prepare_pivot_joins(select, '1', options)
        when 'postgresql'
          prepare_pivot_joins(select, 'true', options)
        when 'mysql2'
          prepare_pivot_joins(select, 'true', options)
        end
        joins(j).select("#{self.table_name}.*, pivoted_abstractions.*")
      end

      ##
      # Pivot grouped abstractions to simulate regular columns on an abstractable entity.
      #
      # Example: an ActiveRecod model RadationTreatment with the columns
      # * 'treatment_date'
      # * 'total_dose'
      # And the abstractions grouped together with the name 'has_treatment_target':
      # * 'has_anatomical_location'.
      # * 'has_laterality'
      #
      # This method allows for the querying of the radiation_treatments table as if
      # it was strucutred like so:
      # 'select id, treatment_date, toatl_dose, has_anatomical_location, has_laterality from radiation_treatments'
      #
      # If an abstractable entity has multiple instances of grouped abstractions the entity will be returned mutlple times.
      #
      # @param [String] abstractor_subject_groups_name name of {Abstractor::Methods::Models:AbtractorSubjectGroup}
      # @param [Hash] options the options to pivot the grouped abstractions.
      # @option options [String] :namespace_type The type parameter of the namespace to pivot grouped abstractions.
      # @option options [Integer] :namespace_id The instance parameter of the namespace to pivot grouped abstractions.
      # @return ActiveRecord::Relation
      # @see Abstractor::Methods::Models:AbstractorSubjectGroup
      def pivot_grouped_abstractions(abstractor_subject_groups_name, options = {})
        options = { grouped: true, namespace_type: nil, namespace_id: nil }.merge(options)
        select = prepare_pivot_select(options)
        select = select + ", abstractor_abstraction_group_id"
        adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]
        j = case adapter
        when 'sqlite3'
          prepare_grouped_pivot_joins(select, "'1'", abstractor_subject_groups_name, options)
        when 'sqlserver'
          prepare_grouped_pivot_joins(select, '1', abstractor_subject_groups_name, options)
        when 'postgresql'
          prepare_grouped_pivot_joins(select, 'true', abstractor_subject_groups_name, options)
        when 'mysql2'
          prepare_grouped_pivot_joins(select, 'true', abstractor_subject_groups_name, options)
        end
        joins(j).select("#{self.table_name}.*, pivoted_abstractions.*")
      end

      private

        def prepare_pivot_select(options= {})
          options.reverse_merge!({ grouped: nil })
          options = { grouped: nil }.merge(options)
          select =[]
          abstractor_abstraction_schemas(options).map(&:predicate).each do |predicate|
            select << "MAX(CASE WHEN data.predicate = '#{predicate}' THEN data.value ELSE NULL END) AS #{predicate}"
          end
          select = select.join(',')
        end

        def prepare_pivot_joins(select, bool, options = {})
          if options[:namespace_type] || options[:namespace_id]
            "LEFT JOIN
            (
            SELECT #{self.table_name}.id AS subject_id,
            #{select}
            FROM
            (SELECT   aas.predicate
                    , aas.id AS abstractor_abstraction_schema_id
                    , asb.subject_type
                    , aa.about_id
                    , CASE WHEN aa.value IS NOT NULL AND aa.value != '' THEN aa.value WHEN aa.unknown = #{bool} THEN 'unknown' WHEN aa.not_applicable = #{bool} THEN 'not applicable' END AS value
            FROM abstractor_abstractions aa JOIN abstractor_subjects asb            ON aa.abstractor_subject_id = asb.id
                                            JOIN abstractor_abstraction_schemas aas ON asb.abstractor_abstraction_schema_id = aas.id
            WHERE asb.subject_type = '#{self.to_s}'
            AND asb.namespace_type = '#{options[:namespace_type]}'
            AND asb.namespace_id = #{options[:namespace_id]}
            AND NOT EXISTS (
              SELECT 1
              FROM abstractor_abstraction_group_members aagm
              WHERE aa.id = aagm.abstractor_abstraction_id
            )
            ) data join #{self.table_name} ON  data.about_id = #{self.table_name}.id
            GROUP BY #{self.table_name}.id
            ) pivoted_abstractions ON pivoted_abstractions.subject_id = #{self.table_name}.id
            "
          else
            "LEFT JOIN
            (
            SELECT #{self.table_name}.id AS subject_id,
            #{select}
            FROM
            (SELECT   aas.predicate
                    , aas.id AS abstractor_abstraction_schema_id
                    , asb.subject_type
                    , aa.about_id
                    , CASE WHEN aa.value IS NOT NULL AND aa.value != '' THEN aa.value WHEN aa.unknown = #{bool} THEN 'unknown' WHEN aa.not_applicable = #{bool} THEN 'not applicable' END AS value
            FROM abstractor_abstractions aa JOIN abstractor_subjects asb            ON aa.abstractor_subject_id = asb.id
                                            JOIN abstractor_abstraction_schemas aas ON asb.abstractor_abstraction_schema_id = aas.id
            WHERE asb.subject_type = '#{self.to_s}'
            AND NOT EXISTS (
              SELECT 1
              FROM abstractor_abstraction_group_members aagm
              WHERE aa.id = aagm.abstractor_abstraction_id
            )
            ) data join #{self.table_name} ON  data.about_id = #{self.table_name}.id
            GROUP BY #{self.table_name}.id
            ) pivoted_abstractions ON pivoted_abstractions.subject_id = #{self.table_name}.id
            "
          end
        end

        def prepare_grouped_pivot_joins(select, bool, abstractor_subject_groups_name, options = {})
          abstractor_subject_group = abstractor_subject_groups(options).detect { |abstractor_subject_group| abstractor_subject_group.name ==  abstractor_subject_groups_name }

          if options[:namespace_type] || options[:namespace_id]
            "JOIN
             (
             SELECT #{self.table_name}.id AS subject_id,
             #{select}
             FROM
             (SELECT   aas.predicate
                     , aas.id AS abstraction_schema_id
                     , asb.subject_type
                     , aa.about_id
                     , CASE WHEN aa.value IS NOT NULL AND aa.value != '' THEN aa.value WHEN aa.unknown = #{bool} THEN 'unknown' WHEN aa.not_applicable = #{bool} THEN 'not applicable' END AS value
                     , aag.id AS abstractor_abstraction_group_id
             FROM abstractor_abstractions aa JOIN abstractor_subjects asb                    ON aa.abstractor_subject_id = asb.id
                                             JOIN abstractor_abstraction_schemas aas         ON asb.abstractor_abstraction_schema_id = aas.id
                                             JOIN abstractor_abstraction_group_members aagm  ON aa.id = aagm.abstractor_abstraction_id
                                             JOIN abstractor_abstraction_groups aag          ON aagm.abstractor_abstraction_group_id= aag.id
             WHERE asb.subject_type = '#{self.to_s}'
             AND asb.namespace_type = '#{options[:namespace_type]}'
             AND asb.namespace_id = #{options[:namespace_id]}
             AND aag.abstractor_subject_group_id = #{abstractor_subject_group.id}
             ) data join #{self.table_name} ON  data.about_id = #{self.table_name}.id
             GROUP BY #{self.table_name}.id, abstractor_abstraction_group_id
             ) pivoted_abstractions ON pivoted_abstractions.subject_id = #{self.table_name}.id
             "
           else
             "JOIN
              (
              SELECT #{self.table_name}.id AS subject_id,
              #{select}
              FROM
              (SELECT   aas.predicate
                      , aas.id AS abstraction_schema_id
                      , asb.subject_type
                      , aa.about_id
                      , CASE WHEN aa.value IS NOT NULL AND aa.value != '' THEN aa.value WHEN aa.unknown = #{bool} THEN 'unknown' WHEN aa.not_applicable = #{bool} THEN 'not applicable' END AS value
                      , aag.id AS abstractor_abstraction_group_id
              FROM abstractor_abstractions aa JOIN abstractor_subjects asb                    ON aa.abstractor_subject_id = asb.id
                                              JOIN abstractor_abstraction_schemas aas         ON asb.abstractor_abstraction_schema_id = aas.id
                                              JOIN abstractor_abstraction_group_members aagm  ON aa.id = aagm.abstractor_abstraction_id
                                              JOIN abstractor_abstraction_groups aag          ON aagm.abstractor_abstraction_group_id= aag.id
              WHERE asb.subject_type = '#{self.to_s}'
              AND aag.abstractor_subject_group_id = #{abstractor_subject_group.id}
              ) data join #{self.table_name} ON  data.about_id = #{self.table_name}.id
              GROUP BY #{self.table_name}.id, abstractor_abstraction_group_id
              ) pivoted_abstractions ON pivoted_abstractions.subject_id = #{self.table_name}.id
              "
           end
        end
    end
  end
end