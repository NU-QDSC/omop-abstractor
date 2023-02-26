require 'rails_helper'
describe  Abstractor::AbstractorAbstractionSource do
  before(:each) do
    Abstractor::Setup.system
    @list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
    @value_rule_type = Abstractor::AbstractorRuleType.where(name: 'value').first
    @source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
    @abstractor_abstraction_schema = FactoryGirl.create(:abstractor_abstraction_schema, predicate: 'has_some_property', display_name: 'some_property', abstractor_object_type: @list_object_type, preferred_name: 'some property')
    @abstractor_subject = FactoryGirl.create(:abstractor_subject, subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema: @abstractor_abstraction_schema)
    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
    @note = FactoryGirl.create(:note, person: @person, note_text: 'Little my says hi!')
    @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
  end

  it "can normalize its from method from a string", focus: false do
    abstractor_abstraction_source = FactoryGirl.create(:abstractor_abstraction_source, abstractor_subject: @abstractor_subject, from_method: 'note_text',  abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion)
    expect(abstractor_abstraction_source.normalize_from_method_to_sources(@note_stable_identifier)).to eq([ { source_type: NoteStableIdentifier, source_id: @note_stable_identifier.id, source_method: "note_text", section_name: nil }])
  end

  it "can normalize its from method when the method returns nil", focus: false do
    NoteStableIdentifier.send(:define_method, '@note_stable_identifier_nil') do
      nil
    end
    note = FactoryGirl.create(:note, person: @person, note_text: "can't be nil")
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    abstractor_abstraction_source = FactoryGirl.create(:abstractor_abstraction_source, abstractor_subject: @abstractor_subject, from_method: '@note_stable_identifier_nil', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion)
    expect(abstractor_abstraction_source.normalize_from_method_to_sources(note_stable_identifier)).to eq([{ source_type: NoteStableIdentifier, source_id: note_stable_identifier.id, source_method: "@note_stable_identifier_nil", section_name: nil }])
  end

  it "can normalize its from method when it is nil", focus: false do
    note = FactoryGirl.create(:note, person: @person, note_text: "can't be nil")
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)

    abstractor_abstraction_source = FactoryGirl.create(:abstractor_abstraction_source, abstractor_subject: @abstractor_subject, from_method: nil, abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion)
    expect(abstractor_abstraction_source.normalize_from_method_to_sources(note_stable_identifier)).to eq([{ source_type: NoteStableIdentifier, source_id: note_stable_identifier.id, source_method: nil, section_name: nil }])
  end

  it "can normalize its from method from a custom method", focus: false do
    NoteStableIdentifier.send(:define_method, '@note_stable_identifier') do
      [{ source_type: nil , source_id: nil , source_method: nil }]
    end

    abstractor_abstraction_source = FactoryGirl.create(:abstractor_abstraction_source, abstractor_subject: @abstractor_subject, from_method: '@note_stable_identifier', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion)
    expect(abstractor_abstraction_source.normalize_from_method_to_sources(@note_stable_identifier)).to eq([{ source_type: nil, source_id: nil, source_method: nil }])
  end

  describe 'sections' do
    before(:each) do
      Abstractor::Setup.system
      @list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
      @value_rule_type = Abstractor::AbstractorRuleType.where(name: 'value').first
      @source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
      @abstractor_abstraction_schema_moomin = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_favorite_moomin', display_name: 'Has favorite moomin', abstractor_object_type_id: @list_object_type.id, preferred_name: 'Has favorite moomin').first_or_create

      ['Moomintroll', 'Little My', 'The Groke'].each do |moomin|
        abstractor_object_value = FactoryGirl.create(:abstractor_object_value, value: moomin)
        Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @abstractor_abstraction_schema_moomin, abstractor_object_value: abstractor_object_value)
      end

      @abstractor_subject_moomin = Abstractor::AbstractorSubject.create(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema: @abstractor_abstraction_schema_moomin)
    end

    it 'across the complete source note if no section is specified', focus: false do
    note_text=<<EOS
I like little my the best!
favorite moomin:
The groke is the bomb!
EOS
      abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion)
      note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      source = abstractor_abstraction_source.normalize_from_method_to_sources(note_stable_identifier).first
      note_stable_identifier.abstract
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source)).to eq(note_text)
      puts 'hello booch'
      expect(Set.new(note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_moomin).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(["Little My", "The Groke"]))
    end

    it 'across a section of the source note based on a name/value section type', focus: false do
    note_text=<<EOS
I like little my the best!
favorite moomin:
The groke is the bomb!
EOS

      abstractor_section_type_name_value = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_NAME_VALUE).first
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', delimiter: ':')
      abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'favorite moomin')
      note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      source = abstractor_abstraction_source.normalize_from_method_to_sources(note_stable_identifier).first
      note_stable_identifier.abstract
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source)).to eq("\nThe groke is the bomb!\n")
      expect(Set.new(note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_moomin).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(["The Groke"]))
    end

    it 'across a section of the source note based on a name/value section type across multiple sections', focus: false do
    note_text=<<EOS
I like little my the best!
favorite moomin:
The groke is the bomb!

my other section:
Section two is better

yet another section: no more tears

Last section :
the end
of story
goes here
EOS

      abstractor_section_type_name_value = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_NAME_VALUE).first
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', delimiter: ':')
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'my other section', delimiter: ':')
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'yet another section', delimiter: ':')
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'last section', delimiter: ':')
      abstractor_abstraction_source_1 = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'favorite moomin')
      abstractor_abstraction_source_2 = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'my other section')
      abstractor_abstraction_source_3 = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'yet another section')
      abstractor_abstraction_source_4 = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'last section')
      note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      source_1 = abstractor_abstraction_source_1.normalize_from_method_to_sources(note_stable_identifier).last
      source_2 = abstractor_abstraction_source_2.normalize_from_method_to_sources(note_stable_identifier).last
      source_3 = abstractor_abstraction_source_3.normalize_from_method_to_sources(note_stable_identifier).last
      source_4 = abstractor_abstraction_source_4.normalize_from_method_to_sources(note_stable_identifier).last
      note_stable_identifier.abstract
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source_1)).to eq("\nThe groke is the bomb!\n")
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source_2)).to eq("\nSection two is better\n")
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source_3)).to eq(" no more tears\n")
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source_4)).to eq("\nthe end\nof story\ngoes here\n")
      expect(Set.new(note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_moomin).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(["The Groke"]))
    end

    it 'across a section of the source note based on a name/value section type with section value on the same line as the section name (ignoring trailing spaces in the section name)', focus: false do
    note_text=<<EOS
I like little my the best!
favorite moomin : The groke is the bomb!

delicious cusine: italian

EOS

      abstractor_section_type_name_value = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_NAME_VALUE).first
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', delimiter: ':')
      abstractor_abstraction_source_1 = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'favorite moomin')
      note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      source_1 = abstractor_abstraction_source_1.normalize_from_method_to_sources(note_stable_identifier).last
      note_stable_identifier.abstract
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source_1)).to eq(" The groke is the bomb!\n")
      expect(Set.new(note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_moomin).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(["The Groke"]))
    end

    it 'across a section of the source note based on a name/value section type with section value on the same line as the section name', focus: false do
    note_text=<<EOS
I like little my the best!
favorite moomin: The groke is the bomb!

delicious cusine: italian

EOS

      abstractor_section_type_name_value = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_NAME_VALUE).first
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', delimiter: ':')
      abstractor_abstraction_source_1 = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'favorite moomin')
      note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      source_1 = abstractor_abstraction_source_1.normalize_from_method_to_sources(note_stable_identifier).last
      source_1 = abstractor_abstraction_source_1.normalize_from_method_to_sources(note_stable_identifier).last
      note_stable_identifier.abstract
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source_1)).to eq(" The groke is the bomb!\n")
      expect(Set.new(note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_moomin).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(["The Groke"]))
    end

    it 'across a section of the source note based on a name/value section type with a section value on subsequent lines from the section name', focus: false do
    note_text=<<EOS
I like little my the best!
favorite moomin:

The groke is the bomb!
Though he is very scary.

delicious cusine: italian

EOS

      abstractor_section_type_name_value = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_NAME_VALUE).first
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', delimiter: ':')
      abstractor_abstraction_source_1 = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'favorite moomin')
      note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      source_1 = abstractor_abstraction_source_1.normalize_from_method_to_sources(note_stable_identifier).last
      note_stable_identifier.abstract
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source_1)).to eq("\n\nThe groke is the bomb!\nThough he is very scary.\n")
      expect(Set.new(note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_moomin).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(["The Groke"]))
    end

    it 'across a section of the source note based on a name/value section type with a section value on the same and subsequent lines of the section name', focus: false do
    note_text=<<EOS
I like little my the best!
favorite moomin: The groke is the bomb!
Though he is very scary.

delicious cusine: italian

EOS

      abstractor_section_type_name_value = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_NAME_VALUE).first
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', delimiter: ':')
      abstractor_abstraction_source_1 = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'favorite moomin')
      note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      source_1 = abstractor_abstraction_source_1.normalize_from_method_to_sources(note_stable_identifier).last
      note_stable_identifier.abstract
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source_1)).to eq(" The groke is the bomb!\nThough he is very scary.\n")
      expect(Set.new(note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_moomin).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(["The Groke"]))
    end

    it 'across a section of the source note based on a name/value section type with a section value on multiple lines (recognizing non-delimiiting use of delimiters)', focus: false do
    pending "Expected to fail: Need to figure out a way to disambiguate non-delimiting uses of section delimitiers."
    note_text=<<EOS
I like little my the best!
favorite moomin: The groke is the bomb!
Though he is very scary.
I discovered him at 3:00 in the afternoon.

delicious cusine: italian

EOS

      abstractor_section_type_name_value = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_NAME_VALUE).first
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', delimiter: ':')
      abstractor_abstraction_source_1 = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'favorite moomin')
      note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      source_1 = abstractor_abstraction_source_1.normalize_from_method_to_sources(note_stable_identifier).last
      note_stable_identifier.abstract
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source_1)).to eq(" The groke is the bomb!\nThough he is very scary.\nI discovered him at 3:00 in the afternoon.\n")
      expect(Set.new(note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_moomin).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(["The Groke"]))
    end

    it 'across the complete source note based on a name/value section type if a section cannot be found and is instructed to return the whole note upon no match', focus: false do
    note_text=<<EOS
I like little my the best!
cool moomin character:
The groke is the bomb!
EOS

      abstractor_section_type_name_value = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_NAME_VALUE).first
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', return_note_on_empty_section: true, delimiter: ':')
      abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'favorite moomin')
      note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      source = abstractor_abstraction_source.normalize_from_method_to_sources(note_stable_identifier).first
      note_stable_identifier.abstract
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source)).to eq(note_text)
      expect(Set.new(note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_moomin).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(["Little My", "The Groke"]))
    end

    it 'across an empty note based on a name/value section type if a section cannot be found and is instructed to not return the whole note upon no match', focus: false do
    note_text=<<EOS
I like little my the best!
favorite moomin character:
The groke is the bomb!
EOS

      abstractor_section_type_name_value = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_NAME_VALUE).first
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', return_note_on_empty_section: false, delimiter: ':')
      abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'favorite moomin')
      note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      source = abstractor_abstraction_source.normalize_from_method_to_sources(note_stable_identifier).first
      note_stable_identifier.abstract
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source)).to eq('')
      expect(Set.new(note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_moomin).abstractor_suggestions.map(&:suggested_value))).to eq(Set.new([nil]))
    end

    it 'across a section of the source note based on a name/value section type name varaint', focus: false do
    note_text=<<EOS
I like little my the best!
beloved moomin:
The groke is the bomb!
EOS

      abstractor_section_type_name_value = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_NAME_VALUE).first
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', delimiter: ':')
      abstractor_section_name_varaint = Abstractor::AbstractorSectionNameVariant.create(abstractor_section: abstractor_section, name: 'beloved moomin')
      abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'favorite moomin')
      note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      source = abstractor_abstraction_source.normalize_from_method_to_sources(note_stable_identifier).first
      note_stable_identifier.abstract
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source)).to eq("\nThe groke is the bomb!\n")
      expect(Set.new(note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_moomin).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(["The Groke"]))
    end

    it 'across a section of the source note based on a custom section type', focus: false do
    note_text=<<EOS
I like little my the best!
Bad ass moomin--
The groke is the bomb!
EOS

      abstractor_section_type_name_value = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_CUSTOM).first
      abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', custom_regular_expression: "(?<=^|[\r\n])([A-Z][^delimiter]*)delimiter([^\r\n]*(?:[\r\n]+(?![A-Z].*delimiter).*)*)", delimiter: '--')
      abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: @value_rule_type, abstractor_abstraction_source_type: @source_type_nlp_suggestion, section_name: 'favorite moomin')
      note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      source = abstractor_abstraction_source.normalize_from_method_to_sources(note_stable_identifier).first
      note_stable_identifier.abstract
      expect(Abstractor::AbstractorAbstractionSource.abstractor_text(source)).to eq("\nThe groke is the bomb!\n")
      expect(Set.new(note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_moomin).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(["The Groke"]))
    end
  end
end