require 'spec_helper_acceptance'
require 'json'
describe 'System Ruby with No SSL, Not protected, No mcollective' do
  context 'default parameters' do
    let(:pp) do
      "
      class { 'r10k':
        remote => 'git@github.com:someuser/puppet.git',
      }
      class {'r10k::webhook::config':
        enable_ssl      => false,
        protected       => false,
        use_mcollective => false,
        notify     => Service['webhook'],
      }

      class {'r10k::webhook':
        require => Class['r10k::webhook::config'],
      }
      "
    end
    it 'applies with no errors' do
      apply_manifest(pp, :catch_failures => true) # rubocop:disable Style/HashSyntax
    end
    it 'is idempotent' do
      apply_manifest(pp, :catch_changes => true) # rubocop:disable Style/HashSyntax
    end
    describe service('webhook') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
    it 'supports style Github payloads via module end point' do
      shell('/usr/bin/curl -d \'{ "repository": { "name": "puppetlabs-stdlib" } }\' -H "Accept: application/json" "http://localhost:8088/module" -k -q') do |r|
        expect(r.stdout).to match(%r{^.*success.*$})
        expect(r.exit_code).to eq(0)
      end
    end
    it 'supports style Bitbucket payloads via module end point' do
      shell('/usr/bin/curl -X POST -d \'{ "repository": { "full_name": "puppetlabs/puppetlabs-stdlib", "name": "PuppetLabs : StdLib" } }\' "http://localhost:8088/module" -k -q') do |r|
        expect(r.stdout).to match(%r{^.*success.*$})
        expect(r.exit_code).to eq(0)
      end
    end
    it 'supports style Github payloads via payload end point' do
      shell('/usr/bin/curl -d \'{ "ref": "refs/heads/production" }\' -H "Accept: application/json" "http://localhost:8088/payload" -k -q') do |r|
        expect(r.stdout).to match(%r{^.*success.*$})
        expect(r.exit_code).to eq(0)
      end
    end
    it 'supports style Gitorious payloads via payload end point' do
      shell('/usr/bin/curl -X POST -d \'%7b%22ref%22%3a%22master%22%7d\' "http://localhost:8088/payload" -q') do |r|
        expect(r.stdout).to match(%r{^.*success.*$})
        expect(r.exit_code).to eq(0)
      end
    end
    it 'supports style BitBucket payloads via payload end point' do
      shell('/usr/bin/curl -X POST -d \'{ "push": { "changes": [ { "new": { "name": "production" } } ] } }\' "http://localhost:8088/payload" -q') do |r|
        expect(r.stdout).to match(%r{^.*success.*$})
        expect(r.exit_code).to eq(0)
      end
    end
  end
end
