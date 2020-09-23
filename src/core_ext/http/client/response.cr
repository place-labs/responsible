# Provide an explicit return type (missing from stb-lib) to prevent the compiler
# warning when injecting `Responsible::ResponseInterface`.

# :nodoc:
class HTTP::Client::Response
  def body? : String?
    previous_def
  end
end
