require 'rails_helper'
describe Abstractor::Utility do
  it 'uniquifies overlaping match values', focus: false do
    match_values =['little my is a moomin', 'little my is a moomin par excellence']
    expect(Abstractor::Utility.uniquify_overlapping_match_values(match_values)).to eq(["little my is a moomin par excellence"])
  end

  it 'does not uniquify non overlapping match value', focus: false do
    match_values =['little my is a moomin', 'little my is a geat moomin par excellence']
    expect(Abstractor::Utility.uniquify_overlapping_match_values(match_values)).to eq(["little my is a geat moomin par excellence", "little my is a moomin"])
  end
end