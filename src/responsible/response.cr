require "http/client/response"
require "json"
require "./response_type"

class Responsible::Response
  @response : HTTP::Client::Response
  @type : ResponseType
  @in_handler : Bool = false

  def initialize(@response)
    @type = ResponseType.from(@response.status)
    run_global_handler
  end

  forward_missing_to @response

  private def run(&block : Action)
    @in_handler = true
    yield self
    @in_handler = false
  end

  # Executes a global handler for the reponse type, if registered.
  private def run_global_handler
    handler = HANDLERS[@type]?
    run(&handler) if handler
  end

  {% for response_type in ResponseType.constants.map(&.underscore) %}
    # Execute the passed block if this is a {{response_type}} response.
    def on_{{response_type}}(&block : Action) : self
      if @type.{{response_type}}?
        run { yield self }
      end
      self
    end
  {% end %}


  # Reads the contents of the body into the specified type *x*.
  #
  # If the response cannot be parsed, the block will be yielded to to provide an
  # alternative parser.
  #
  # `T.from_json` must exist and be capable of deserializing a JSON string.
  # This works out-of-the-box for most types where attributes map directly. The
  # `JSON::Serializable` module provides tools for more complex parsing.
  def parse_to(x : T.class, ignore_response_code = @in_handler, &block : Exception -> U) : T | U forall T, U
    raise Error.from(self) unless success? || ignore_response_code

    case headers["content-type"]
    when .starts_with? "application/json"
      begin
        T.from_json(body || body_io)
      rescue e
        yield e
      end
    else
      raise Error.new "unsupported content type (#{content_type})"
    end
  end

  # Parses the contents of this response to the type *x*, or raises an
  # `Responsible::Error` if this is not possible.
  def parse_to(x : T.class, ignore_response_code = @in_handler) : T forall T
    parse_to(x, ignore_response_code) do |error|
      raise Error.new "Could not parse to #{T}: #{error.message}", cause: error
    end
  end

  # Parses the contents of this response to the type *x*, or nil if this is not
  # possible.
  def parse_to?(x : T.class, ignore_response_code = @in_handler) : T? forall T
    parse_to(x, ignore_response_code) do
      nil
    end
  end

  # Parses the contents of this response to the type *x*, or raises an
  # `Responsible::Error` if this is not possible.
  def >>(x : T.class) : T forall T
    parse_to x
  end
end
