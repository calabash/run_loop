require 'erb'

module RunLoop

  # @!visibility private
  # Class to break up javascript templates in to reusable chunks
  class UIAScriptTemplate < ERB

    # @!visibility private
    def initialize(template_root, template_relative_path)
      @template_root = template_root
      template_path = File.join(@template_root, template_relative_path)
      @template = File.read(template_path).force_encoding("utf-8")
      super(@template)
    end

    # @!visibility private
    def render_template(template_relative_path)
      UIAScriptTemplate.new(@template_root, template_relative_path).result
    end

    # @!visibility private
    def result
      super(binding)
    end

    # @!visibility private
    def self.sub_path_var!(javascript, results_dir)
      self.substitute_variable!(javascript, "PATH", results_dir)
    end

    # @!visibility private
    def self.sub_read_script_path_var!(javascript, read_cmd_sh)
      self.substitute_variable!(javascript, "READ_SCRIPT_PATH", read_cmd_sh)
    end

    # @!visibility private
    def self.sub_timeout_script_path_var!(javascript, timeout_sh)
      self.substitute_variable!(javascript, "TIMEOUT_SCRIPT_PATH", timeout_sh)
    end

    # @!visibility private
    def self.sub_flush_uia_logs_var!(javascript, value)
      self.substitute_variable!(javascript, "FLUSH_LOGS", value)
    end

    # @!visibility private
    #
    # Legacy and XTC - related to :no_flush which is a deprecated option.
    #
    # Replaced with :flush_uia_logs
    def self.sub_mode_var!(javascript, value)
      self.substitute_variable!(javascript, "MODE", value)
    end

    # @!visibility private
    def self.substitute_variable!(javascript, variable, value)
      javascript.gsub!(/\$#{variable}/, value)
    end
  end
end
