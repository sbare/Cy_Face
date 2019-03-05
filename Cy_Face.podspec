
Pod::Spec.new do |s|
    s.name         = 'Cy_Face'
    s.version      = '1.0.0'
    s.summary      = 'An easy way to use pull-to-refresh'
    s.homepage     = 'https://github.com/sbare/Cy_Face'
    s.license      = 'MIT'
    s.authors      = { "cyc" => "939806859@qq.com" }
    s.platform     = :ios, '8.0'
    s.source       = {:git => 'https://github.com/sbare/Cy_Face.git', :tag => s.version}
    s.source_files = "Cy_Face/**/*.{h,m}"
    s.requires_arc = true
    s.vendored_frameworks = 'Cy_Face/**/ArcSoftFaceEngine.framework'
end

