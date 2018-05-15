require 'netsuite'

def initialize()
  NetSuite.configure do
    reset!
    api_version	ENV['API_VERSION']  #'2017_2'
    wsdl          "https://webservices.eu1.netsuite.com/wsdl/v#{api_version}_0/netsuite.wsdl"
    wsdl_domain   "webservices.eu1.netsuite.com"
    read_timeout  100000
    email    	ENV['EMAIL'] 
    password 	ENV['PASSWORD'] 
    account   ENV['ACCOUNT'] 
    role      ENV['ROLE'] 

  end

  NetSuite::Configuration.soap_header = {
     'platformMsgs:ApplicationInfo' => {
        'platformMsgs:applicationId' => ENV['APPLICATION_ID'] 
     }
  }
end


def updateFile(id, path)
  data = File.read(path)
  enc  = Base64.encode64(data)
  file = NetSuite::Records::File.get(:internal_id => id)
  file.update(content: enc)
end


def searchForFile(name)
  search = NetSuite::Records::File.search({
    basic: [
      {
        field: 'name',
        operator: 'is',
        value: name
      }
    ]
  })
  if search.results.length > 0 then 
    return search.results[0]
  else 
    return nil
  end
end
input = ARGV
initialize()
filename = input[0].match(/(?:\/.*)*(\d{3}.*)/).captures
file = searchForFile(filename)
if file.nil?
  puts 'No file found'
  abort
end
updateFile(file.internal_id, input[0])

