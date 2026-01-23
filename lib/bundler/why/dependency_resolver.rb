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

      # 依存関係チェーンを取得（Gemfileに書かれたgemまで遡る）
      def find_dependency_chain(target_name)
        spec = find_spec(target_name)
        return [] unless spec

        chains = []
        gemfile_dependencies = @definition.dependencies.map(&:name)

        # 直接の依存元を探す
        direct_dependents = find_direct_dependents(spec)

        direct_dependents.each do |dependent|
          # 依存元がGemfileに記載されているかチェック
          if gemfile_dependencies.include?(dependent[:name])
            chains << [dependent[:name], target_name]
          else
            # 依存元をさらに遡る
            parent_chains = find_dependency_chain_recursive(dependent[:name], [target_name], gemfile_dependencies)
            chains.concat(parent_chains)
          end
        end

        chains.uniq
      end

      # Gemfileのdependenciesを取得
      def gemfile_dependencies
        @definition.dependencies.map(&:name)
      end

      # 依存関係ツリーを構築（各ノードの子を取得）
      def build_dependents_tree(spec_name, visited = Set.new, depth = 0)
        return [] if visited.include?(spec_name) || depth > 10

        visited.add(spec_name)
        spec = find_spec(spec_name)
        return [] unless spec

        direct_dependents = []
        @specs.each do |other_spec|
          other_spec.dependencies.each do |dep|
            if dep.name == spec_name
              direct_dependents << {
                name: other_spec.name,
                version: other_spec.version.to_s,
                requirement: dep.requirement.to_s,
                children: build_dependents_tree(other_spec.name, visited.dup, depth + 1)
              }
            end
          end
        end

        direct_dependents
      end

      private

      # 依存関係チェーンを再帰的に遡る
      def find_dependency_chain_recursive(current_name, path, gemfile_deps)
        chains = []

        # 循環参照を防ぐため、すでにpathに含まれている場合は処理しない
        return chains if path.include?(current_name)

        current_spec = find_spec(current_name)
        return chains unless current_spec

        # 現在のgemの依存元を取得
        direct_dependents = find_direct_dependents(current_spec)

        if direct_dependents.empty?
          # 依存元がない場合でも、Gemfileに記載されていれば追加
          if gemfile_deps.include?(current_name)
            chains << ([current_name] + path)
          end
        else
          direct_dependents.each do |dependent|
            new_path = [current_name] + path

            if gemfile_deps.include?(dependent[:name])
              # Gemfileに記載されているgemに到達したらチェーンを確定
              chains << ([dependent[:name]] + new_path)
            else
              # さらに親を遡る
              parent_chains = find_dependency_chain_recursive(dependent[:name], new_path, gemfile_deps)
              chains.concat(parent_chains)
            end
          end
        end

        chains
      end

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
