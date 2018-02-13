require 'spec_helper'

module GitDiffParser
  describe Patch do
    describe '#changed_lines' do
      it 'returns lines that were modified' do
        patch_body = File.read('spec/support/fixtures/patch.diff')
        patch = Patch.new(patch_body)

        expect(patch.changed_lines.size).to eq(3)
        expect(patch.changed_lines.map(&:number)).to eq [14, 22, 54]
        expect(patch.changed_lines.map(&:patch_position)).to eq [5, 13, 37]
      end

      context 'when body is nil' do
        it 'returns no lines' do
          patch = Patch.new(nil)

          expect(patch.changed_lines.size).to eq(0)
        end
      end
    end

    describe '#removed_lines' do
      it 'returns lines that were modified' do
        patch_body = File.read('spec/support/fixtures/patch.diff')
        patch = Patch.new(patch_body)

        expect(patch.removed_lines.size).to eq(7)
        expect(patch.removed_lines.map(&:number)).to eq [14, 38, 39, 40, 41, 42, 58]
        expect(patch.removed_lines.map(&:patch_position)).to eq [4, 21, 22, 23, 24, 25, 36]
      end

      context 'when body is nil' do
        it 'returns no lines' do
          patch = Patch.new(nil)

          expect(patch.removed_lines.size).to eq(0)
        end
      end
    end

    describe '#changed_line_numbers' do
      it 'returns line numbers that were modified' do
        patch_body = File.read('spec/support/fixtures/patch.diff')
        patch = Patch.new(patch_body)

        expect(patch.changed_line_numbers.size).to eq(3)
        expect(patch.changed_line_numbers).to eq [14, 22, 54]
      end

      context 'when body is nil' do
        it 'returns no line numbers' do
          patch = Patch.new(nil)

          expect(patch.changed_line_numbers.size).to eq(0)
        end
      end
    end

    describe '#removed_line_numbers' do
      it 'returns line numbers that were removed' do
        patch_body = File.read('spec/support/fixtures/patch.diff')
        patch = Patch.new(patch_body)

        expect(patch.removed_line_numbers.size).to eq(7)
        expect(patch.removed_line_numbers).to eq  [14, 38, 39, 40, 41, 42, 58]
      end

      context 'when body is nil' do
        it 'returns no line numbers' do
          patch = Patch.new(nil)

          expect(patch.changed_line_numbers.size).to eq(0)
        end
      end
    end

    describe '#find_patch_position_by_line_number' do
      it 'returns patch position that were included' do
        patch_body = File.read('spec/support/fixtures/patch.diff')
        patch = Patch.new(patch_body)
        position = 5

        expect(patch.find_patch_position_by_line_number(12)).to be_nil
        expect(patch.find_patch_position_by_line_number(14)).to eq(position)
      end

      context 'when body is nil' do
        it 'returns no patch position' do
          patch = Patch.new(nil)

          expect(patch.find_patch_position_by_line_number(14)).to be_nil
        end
      end
    end

    describe '#find_previous_position_by_line_number' do
      it 'gives old file line position if line existed' do
        patch_body = File.read('spec/support/fixtures/patch.diff')
        patch = Patch.new(patch_body)
        position = 59

        expect(patch.find_previous_position_by_line_number(14)).to be_nil
        expect(patch.find_previous_position_by_line_number(55)).to eq(position)
      end

      context 'when body is nil' do
        it 'returns no position' do
          patch = Patch.new(nil)

          expect(patch.find_patch_position_by_line_number(14)).to be_nil
        end
      end
    end

    describe '#removed_lines_position_in_new' do
      it 'returns array of results for a patch' do
        patch_body = File.read('spec/support/fixtures/patch.diff')
        patch = Patch.new(patch_body)

        expect(patch.removed_lines_position_in_new).to eq([14, 39, 39, 39, 39, 39, 54])
      end

      context 'when body is nil' do
        it 'returns empty array' do
           patch = Patch.new(nil)

           expect(patch.removed_lines_position_in_new.size).to eq(0)
        end
      end
    end
  end
end
