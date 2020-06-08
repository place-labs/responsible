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

  # Wraps a expression that returns a supported response object into a
  # `Responsible::Response` before attempting to parse this out into the return
  # type of the surrounding method.
  #
  # This may be 
  macro parse_to_return_type(&block)
    \{{ raise "no return type on method" if @def.return_type.is_a? Nop }}
    %response = begin
      {{ block.body }}
    end
    Responsible::Response.new(%response).parse_to(\{{ @def.return_type }})
  end
end

Responsible.support HTTP::Client::Response
