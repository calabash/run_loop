class SimControl

  def quit_simulator
    `echo 'application "iPhone Simulator" quit' | osascript`
    `echo 'application "iOS Simulator" quit' | osascript`
  end

end