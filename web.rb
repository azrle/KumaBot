require 'sinatra/base'

module KumaBot
  class Web < Sinatra::Base
    get '/' do
      'Kuma kuma!'
    end
  end
end
