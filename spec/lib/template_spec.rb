
describe RunLoop::UIAScriptTemplate do

  let(:javascript) do
    %q[
var myVar = "$MY_VAR";
var commandPath = "$PATH";
var timeoutScriptPath = "$TIMEOUT_SCRIPT_PATH";
var readPipeScriptPath = "$READ_SCRIPT_PATH";
var N = "$FLUSH_LOGS" == "FLUSH_LOGS" ? 16384 : 0;
var N = "$MODE" == "FLUSH" ? 16384 : 0;
]
  end

  let(:replacement) { "REPLACED" }

  describe ".substitute_variable!" do
    it "replaces variables if they are found" do
      variable = "MY_VAR"
      expected = %Q[var myVar = "#{replacement}";]

      RunLoop::UIAScriptTemplate.substitute_variable!(javascript,
                                                      variable,
                                                      replacement)

      expect(javascript[/#{expected}/, 0]).to be_truthy
    end

    it "does nothing otherwise" do
      variable = "YOUR_VAR"
      expected = javascript.dup
      RunLoop::UIAScriptTemplate.substitute_variable!(javascript,
                                                      variable,
                                                      replacement)

      expect(javascript).to be == expected
    end

    it ".sub_flush_uia_logs_var!" do
      expected = %Q[var N = "#{replacement}" == "FLUSH_LOGS" ? 16384 : 0;]

      RunLoop::UIAScriptTemplate.sub_flush_uia_logs_var!(javascript,
                                                         replacement)

      actual = javascript.split($-0)[5]
      expect(actual).to be == expected
    end

    it ".sub_mode_var!" do
      expected = %Q[var N = "#{replacement}" == "FLUSH" ? 16384 : 0;]

      RunLoop::UIAScriptTemplate.sub_mode_var!(javascript,
                                               replacement)

      actual = javascript.split($-0)[6]
      expect(actual).to be == expected
    end

    it ".sub_path_var!" do
      expected = %Q[var commandPath = "#{replacement}";]
      RunLoop::UIAScriptTemplate.sub_path_var!(javascript,
                                                              replacement)

      actual = javascript.split($-0)[2]
      expect(actual).to be == expected
    end

    it ".sub_read_timeout_script_path_var!" do
      replacement = "REPLACED"
      expected = %Q[var timeoutScriptPath = "#{replacement}";]
      RunLoop::UIAScriptTemplate.sub_timeout_script_path_var!(javascript,
                                                              replacement)

      actual = javascript.split($-0)[3]
      expect(actual).to be == expected
    end

    it ".sub_read_script_path_var!" do
      replacement = "REPLACED"
      expected = %Q[var readPipeScriptPath = "#{replacement}";]

      RunLoop::UIAScriptTemplate.sub_read_script_path_var!(javascript,
                                                           replacement)

      actual = javascript.split($-0)[4]
      expect(actual).to be == expected
    end
  end
end