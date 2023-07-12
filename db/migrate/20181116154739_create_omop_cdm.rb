require 'omop/setup'
class CreateOmopCdm < ActiveRecord::Migration[5.2]
  def change
    Omop::Setup.compile_omop_tables
  end
end
