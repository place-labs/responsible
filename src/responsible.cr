require "./responsible/**"
require "http/client/response"

module Responsible
  HANDLERS = {} of ResponseType => Action

  {% for type in ResponseType.constants %}
    # Registers an `Action` to execute every on every {{type}} response.
    def self.on_{{type.underscore}}(&block : Action) : Nil
      HANDLERS[ResponseType::{{type}}] = block
    end
  {% end %}

  macro support(response_type)
    class {{response_type.id}}
      include Responsible::ResponseInterface
    end
  end
end

Responsible.support HTTP::Client::Response
