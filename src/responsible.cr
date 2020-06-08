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

  # Adds Responsible support to the specified response type object.
  #
  # `ResponsibleInterface contains a minimal set of abstract methods that are
  # compatible with `HTTP::Client::Response` as well as many third-party
  # libraries without modification. If you do need to specify an implimentation
  # to map to other types, an option block may be used to specify the required
  # implementations.
  macro support(response_type, &block)
    class {{response_type.id}}
      include Responsible::ResponseInterface

      {{ block.body if block.is_a? AstNode }}
    end
  end
end

Responsible.support HTTP::Client::Response
