require 'rails_helper'
RSpec.feature 'Home', type: :system do
  before(:each) do
    visit root_path
    sleep(1)
  end

  scenario 'works', js: true, focus: false do
    expect(page).to have_css('#home', text: 'OMOP Abstractor')
  end
end