require 'spec_helper'

describe 'drain', type: :integration do
  with_reset_sandbox_before_each

  describe 'static drain' do
    it 'runs the drain script on a job if drain script is present' do
      manifest_hash = Bosh::Spec::Deployments.simple_manifest
      manifest_hash['releases'].first['version'] = 'latest'
      manifest_hash['jobs'][0]['instances'] = 1
      manifest_hash['resource_pools'][0]['size'] = 1
      deploy_simple(manifest_hash: manifest_hash)

      manifest_hash['properties'] ||= {}
      manifest_hash['properties']['test_property'] = 0
      deploy_simple_manifest(manifest_hash: manifest_hash)

      agent_files = Dir["#{current_sandbox.agent_tmp_path}/agent-base-dir-*/*"]
      drain_output = agent_files.detect { |f| File.basename(f) == 'drain-test.log' }
      expect(File.read(drain_output)).to eq("job_unchanged hash_changed\n1\n")
    end
  end

  describe 'dynamic drain' do
    it 'retries after the appropriate amount of time' do
      manifest_hash = Bosh::Spec::Deployments.simple_manifest
      manifest_hash['releases'].first['version'] = 'latest'
      manifest_hash['jobs'][0]['instances'] = 1
      manifest_hash['resource_pools'][0]['size'] = 1
      manifest_hash['properties'] ||= {}
      manifest_hash['properties']['drain_type'] = 'dynamic'
      deploy_simple(manifest_hash: manifest_hash)

      manifest_hash['properties']['test_property'] = 0
      deploy_simple_manifest(manifest_hash: manifest_hash)

      agent_files = Dir["#{current_sandbox.agent_tmp_path}/agent-base-dir-*/*"]
      drain_output = agent_files.detect { |f| File.basename(f) == 'drain-test.log' }
      drain_times = File.read(drain_output).split.map { |time| time.to_i }
      expect(drain_times.size).to eq(3)
      expect(drain_times[1] - drain_times[0]).to be >= 3
      expect(drain_times[2] - drain_times[1]).to be >= 2
    end
  end
end
