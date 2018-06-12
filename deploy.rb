require 'netsuite'
require 'yaml'
require 'tty-prompt'
def initNetsuite(config)
  NetSuite.configure do
    reset!
    api_version      config['api_version']
    wsdl          "https://webservices.eu1.netsuite.com/wsdl/v#{config['api_version']}_0/netsuite.wsdl"
    wsdl_domain   "webservices.eu1.netsuite.com"
    read_timeout  100000
    email     config['auth']['email']
    password  config['auth']['password']
    account   config['auth']['account']
    role      config['auth']['role']
    silent true
  end

  NetSuite::Configuration.soap_header = {
     'platformMsgs:ApplicationInfo' => {
       'platformMsgs:applicationId' =>  config['auth']['application_id']
     }
  }
end

skipFiles = ['async.min.js', 'lodash.js']


def updateFile(id, path)
  data = File.read(path)
  enc  = Base64.encode64(data)
  file = NetSuite::Records::File.get(:internal_id => id)
  res = file.update(content: enc)
  return res
end


def searchForFile(name, foldername)
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
    return search.results.select{|res| res.folder.name == foldername}.first
  else 
    return nil
  end
end



input = ARGV

config = YAML.load_file('config.yml')

files = Dir[input[0]+"/FileCabinet/SuiteScripts/**/*.js"]


prompt = TTY::Prompt.new
allFiles = prompt.yes?('Deploy all files?')
if not allFiles then 
  files = prompt.multi_select("Select files?", files)
end

initNetsuite(config)
files.each do |file|
  filename = file.match(/(?:\/.*\/)*([a-z0-9\_.]*\.js)/).captures
  foldername = file.match(/(SuiteScripts\/\w+)(?:\/)(?:[a-z0-9\_.]*\.js)/).captures
  foldername = foldername[0].sub!("/", " : ")
  puts 'Uploading ' <<  filename[0]
  remoteFile = searchForFile(filename[0],foldername)
  if remoteFile.nil?
    puts 'No file found'
    abort
  end
  res = updateFile(remoteFile.internal_id, file)
  if res then
    puts 'Successfully uploaded ' << filename[0]
  end
end

