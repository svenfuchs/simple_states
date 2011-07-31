source :rubygems

gemspec

group :test do
  platforms :mri_18 do
    gem "require_relative", "~> 1.0.1"
    gem 'ruby-debug'
  end

  platforms :mri_19 do
    gem 'ruby-debug19', :platforms => :mri_19 unless RUBY_VERSION == '1.9.3'
  end
end
