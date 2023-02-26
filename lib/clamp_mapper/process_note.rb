require 'fileutils'

module ClampMapper
  class ProcessNote
    TMP_DIR = 'tmp/clamp_pipeline_cache/'.freeze

    CLAMP_DIR = Rails.configuration.x.clamp.clamp_dir.freeze
    CLAMP_BIN = Rails.configuration.x.clamp.clamp_bin.freeze
    CLAMP_PIPELINE = Rails.configuration.x.clamp.clamp_pipeline.freeze

    def self.process(note_hash)
      begin
        temp_note_dir = TMP_DIR + "#{SecureRandom.hex(10)}/"
        Dir.mkdir(TMP_DIR) unless Dir.exists?(TMP_DIR)
        Dir.mkdir(temp_note_dir)
        Dir.mkdir(temp_note_dir + 'input/')
        Dir.mkdir(temp_note_dir + 'output/')

        File.write(temp_note_dir + 'input/note.txt', note_hash['text'])

        exec_pipeline_cmd = "java -DCLAMPLicenceFile=\"#{CLAMP_DIR}CLAMP.LICENSE\" -Xmx3g"
        exec_pipeline_cmd += " -cp \"#{CLAMP_DIR}bin/#{CLAMP_BIN}\""
        exec_pipeline_cmd += " edu.uth.clamp.nlp.main.PipelineMain"
        exec_pipeline_cmd += " -i \"#{temp_note_dir}input\""
        exec_pipeline_cmd += " -o \"#{temp_note_dir}output\""
        exec_pipeline_cmd += " -p \"#{CLAMP_DIR}pipeline/#{CLAMP_PIPELINE}\""

        if system(exec_pipeline_cmd)
          clamp_xmi_text = File.read(temp_note_dir + 'output/note.xmi')
        else
          clamp_xmi_text = 'There was an error running the pipeline'
        end
      ensure
        FileUtils.remove_dir(temp_note_dir, true)
      end

      note_hash.merge( 'clamp_xmi' => clamp_xmi_text)
    end
  end
end