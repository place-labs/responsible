require "json"
require "mime/media_type"
require "./response_interface"
require "./response_type"

# Wrapper object for lifted responses. Provides extensions need for defining
# locally scoped error behaviors and parse tools for extraction of returned
# data.
class Responsible::Response
  @response : ResponseInterface
  @type : ResponseType
  @in_handler : Bool = false

  # Creates a new `Response` by wrapping a supported response type. *response*
  # must by a type that includes `ResponsibleInterface`. This can be inserted
  # manually, or by using the `Responsible.support` macro.
  def initialize(@response)
    @type = ResponseType.from(@response.status)
    run_global_handler
  end

  forward_missing_to @response

  # Runs the passed action within a handler context.
  private def run(&block : Action)
    @in_handler = true
    yield self
    @in_handler = false
  end

  # Executes a global handler for the reponse type if one is registered.
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

    mime_type = MIME::MediaType.parse headers["Content-Type"]

    if mime_type.media_type == "application/json"
      begin
        T.from_json(@response.body? || @response.body_io)
      rescue e
        yield e
      end
    else
      raise Error.new "unsupported MIME type (#{mime_type})"
    end
  end

  # Parses the contents of this response to the type *x*, or raises an
  # `Responsible::Error` if this is not possible.
  def parse_to(x : T.class, ignore_response_code = @in_handler) : T forall T
    self.parse_to(x, ignore_response_code) do |error|
      raise Error.new "Could not parse to #{T}: #{error.message}", cause: error
    end
  end

  # Parses the contents of this response to the type *x*, or nil if this is not
  # possible.
  def parse_to?(x : T.class, ignore_response_code = @in_handler) : T? forall T
    self.parse_to(x, ignore_response_code) do
      nil
    end
  end

  # Parses the contents of this response to the type *x*.
  #
  # If *x* is nilable, a parser error will result in `nil` being returned,
  # otherwise a `Responsible::Error` will be raised if parsing is not possible.
  def >>(x : T.class) : T forall T
    {% if T.nilable? %}
      self.parse_to? x, ignore_response_code: true
    {% else %}
      self.parse_to x
    {% end %}
  end
end
