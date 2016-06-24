
Pod::Spec.new do |s|

  s.name         = "SlateWebridge"
  s.version      = "3.4.2.1"
  s.summary      = "Bridge between native and js on UIWebView."


  s.description  = <<-DESC
       Bridge between native and js on UIWebView. Support sync/async call.   
  
                   DESC

  s.homepage     = "https://github.com/islate/SlateWebridge"
  s.license      = "Apache 2.0"
  s.author       = { "linyize" => "linyize@gmail.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/islate/SlateWebridge.git", :tag => s.version.to_s }

  s.source_files = 'SlateWebridge/*.{h,m}'
  s.resource = 'SlateWebridge/webridge.js'
  s.dependency 'SlateUtils'

end
