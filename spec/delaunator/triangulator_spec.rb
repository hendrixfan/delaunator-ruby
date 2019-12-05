require 'spec_helper'

RSpec.describe Delaunator::Triangulator do
  context 'correct triangulation' do
    let(:points) { YAML.load_file 'fixtures/ukraine.yml' }
    it 'valid' do
      Delaunator.validate(points)
    end
  end
end
