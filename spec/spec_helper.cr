require "spec"
require "webmock"
require "../src/responsible"

Spec.before_each &->WebMock.reset
