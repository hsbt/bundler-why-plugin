# frozen_string_literal: true

require "bundler"

module Bundler
  module Why
    class DependencyResolver
      def initialize
        @definition = Bundler.definition
        @specs = @definition.specs
      end

      # 指定されたパッケージがなぜ必要かを分析
      def analyze(package_name)
        spec = find_spec(package_name)
        return nil unless spec

        {
          name: spec.name,
          version: spec.version.to_s,
          direct_dependents: find_direct_dependents(spec),
          all_dependents: find_all_dependents(spec),
          path: spec.loaded_from
        }
      end

      # 指定されたパッケージを検索
      def find_spec(package_name)
        @specs.find { |spec| spec.name == package_name || spec.name.downcase == package_name.downcase }
      end

      # 直接的な依存元（親）を取得
      def find_direct_dependents(spec)
        dependents = []
        
        @specs.each do |other_spec|
          other_spec.dependencies.each do |dep|
            if dep.name == spec.name
              dependents << {
                name: other_spec.name,
                version: other_spec.version.to_s,
                requirement: dep.requirement.to_s
              }
            end
          end
        end
        
        dependents
      end

      # すべての依存元（直接・間接）を取得
      def find_all_dependents(spec)
        dependents = Set.new
        queue = [spec.name]
        visited = Set.new

        while queue.any?
          current_name = queue.shift
          next if visited.include?(current_name)
          visited.add(current_name)

          @specs.each do |other_spec|
            other_spec.dependencies.each do |dep|
              if dep.name == current_name
                dependents.add(other_spec.name)
                queue << other_spec.name unless visited.include?(other_spec.name)
              end
            end
          end
        end

        dependents.map do |name|
          dep_spec = find_spec(name)
          {
            name: name,
            version: dep_spec&.version.to_s
          }
        end
      end

      # 依存関係チェーンを取得
      def find_dependency_chain(target_name)
        spec = find_spec(target_name)
        return nil unless spec

        chains = []
        
        # Gemfileの直接の依存関係を確認
        @definition.dependencies.each do |dep|
          if is_dependency_of?(target_name, dep.name)
            chain = trace_chain(dep.name, target_name, [dep.name])
            chains << chain if chain
          end
        end

        chains
      end

      private

      # targetが sourceの依存関係にあるかチェック
      def is_dependency_of?(target, source)
        source_spec = find_spec(source)
        return false unless source_spec

        source_spec.dependencies.any? { |dep| dep.name == target }
      end

      # 依存関係チェーンをトレース
      def trace_chain(current, target, path)
        current_spec = find_spec(current)
        return nil unless current_spec

        return path if current == target

        current_spec.dependencies.each do |dep|
          if is_dependency_of?(target, dep.name)
            chain = trace_chain(dep.name, target, path + [dep.name])
            return chain if chain
          end
        end

        nil
      end
    end
  end
end
