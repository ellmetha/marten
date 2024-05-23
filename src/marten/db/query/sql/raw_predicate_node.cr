module Marten
  module DB
    module Query
      module SQL
        class RawPredicateNode < PredicateNode
          getter statement
          getter params

          def initialize(
            @statement : String,
            @params = [] of ::DB::Any,
            @children = [] of PredicateNode,
            @connector = SQL::PredicateConnector::AND, @negated = false, *args

          )
            @predicates = [] of Predicate::Base
            @predicates.concat(args.to_a)
          end

          def initialize(
            @statement : String,
            @params : Array(::DB::Any) | Hash(String, ::DB::Any),
            @children : Array(PredicateNode),
            @connector : PredicateConnector,
            @negated : Bool,
            @predicates : Array(Predicate::Base)
          )
          end

          def ==(other : RawPredicateNode)
            (
              (other.statement == statement) &&
              (other.predicates == predicates) &&
                (other.children == children) &&
                (other.connector == connector) &&
                (other.negated == negated)
            )
          end

          def clone
            RawPredicateNode.new(
              statement: @statement,
              params: params,
              children: @children.map { |c| c.clone },
              connector: @connector,
              negated: @negated,
              predicates: @predicates.dup
            )
          end

          def to_sql(connection : Connection::Base)
            sql_parts = [] of String
            sql_params = [] of ::DB::Any

            return case params
              when Array(::DB::Any)
                sanitize_positional_parameters(connection)
              else
                sanitize_named_parameters(connection)
              end

            # sanitized_query, sanitized_params = case params
            # when Array(::DB::Any)
            #   sanitize_positional_parameters
            # else
            #   sanitize_named_parameters
            # end

            # sanitized_query, sanitized_params = sanitize_named_parameters

            sql_string = sql_parts.join(" #{@connector} ")

            unless sql_string.empty?
              sql_string = "NOT (#{sql_string})" if @negated
              sql_string = "(#{sql_string})" if sql_parts.size > 1
            end

            {@statement, sql_params}
          end

          private NAMED_PARAMETER_RE = /(:?):([a-zA-Z]\w*)/
          private POSITIONAL_PARAMETER_CHAR = '?'
          private POSITIONAL_PARAMETER_RE   = /#{"\\" + POSITIONAL_PARAMETER_CHAR}/

          private def sanitize_positional_parameters(connection)
            if @statement.count(POSITIONAL_PARAMETER_CHAR) != params.size
              raise Errors::UnmetQuerySetCondition.new("Wrong number of parameters provided for query: #{@statement}")
            end

            parameter_offset = 0
            sanitized_query = @statement.gsub(POSITIONAL_PARAMETER_RE) do
              parameter_offset += 1
              connection.parameter_id_for_ordered_argument(parameter_offset)
            end

            {sanitized_query, params.as(Array(::DB::Any))}
          end

          private def sanitize_named_parameters(connection)
            sanitized_params = [] of ::DB::Any

            parameter_offset = 0
            sanitized_query = @statement.gsub(NAMED_PARAMETER_RE) do |match|
              # Specifically handle PostgreSQL's cast syntax (::).
              next match if $1 == ":"

              parameter_match = $2.to_s
              if !params.as(Hash).has_key?(parameter_match)
                raise Errors::UnmetQuerySetCondition.new("Missing parameter '#{parameter_match}' for query: #{@statement}")
              end

              parameter_offset += 1
              sanitized_params << params.as(Hash(String, ::DB::Any))[parameter_match]
              connection.parameter_id_for_ordered_argument(parameter_offset)
            end

            {sanitized_query, sanitized_params}
          end
        end
      end
    end
  end
end
