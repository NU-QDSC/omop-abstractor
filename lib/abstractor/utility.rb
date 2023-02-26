module Abstractor
  module Utility
    def self.dehumanize(target)
      result = target.to_s.dup
      result.downcase.gsub(/ +/,'_')
    end

    def self.uniquify_overlapping_match_values(match_values)
      match_values.sort! { |a,b| b.size <=> a.size }

      normalized_match_values = []
      sub_match_values = []

      match_values.each do |match_value|
        if !sub_match_values.include?(match_value)
          cached_match_values = match_values.dup
          cached_match_values.delete(match_value)
          cached_match_values.each do |cached_match_value|
            if match_value.include?(cached_match_value)
              sub_match_values << cached_match_value
            end
          end
          normalized_match_values << match_value
        end
      end
      normalized_match_values.compact.uniq
    end
  end
end