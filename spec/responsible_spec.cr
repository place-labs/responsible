require "./spec_helper"

describe Responsible do
  it "supports registering global handlers" do
    WebMock.stub(:get, "www.example.com")
    has_run = false

    Responsible.on_success do
      has_run = true
    end

    ~HTTP::Client.get("www.example.com")

    has_run.should be_true
  end

  it "runs the correct handler" do
    WebMock.stub(:get, "www.example.com").to_return(status: 500)
    error = false
    success = false

    Responsible.on_success do
      success = true
    end

    Responsible.on_server_error do
      error = true
    end

    ~HTTP::Client.get("www.example.com")

    error.should be_true
    success.should be_false
  end
end
