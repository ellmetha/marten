module Marten
  module DB
    module SQL
      class PredicateNode
        def initialize(@children = [] of self, @connector = SQL::PredicateConnector::AND, @negated = false, *args)
          @predicates = [] of Predicate::Base
          @predicates.concat(args.to_a)
        end

        def initialize(
          @children : Array(self),
          @connector : PredicateConnector,
          @negated : Bool,
          @predicates : Array(Predicate::Base)
        )
        end

        protected getter predicates

        protected def add(other : self, conn : SQL::PredicateConnector)
          return if @children.includes?(other)

          if @connector == conn
            @children << other
          else
            new_child = self.class.new(
              children: @children,
              connector: @connector,
              negated: @negated,
              predicates: @predicates
            )
            @connector = conn
            @children = [new_child, other]
          end
        end

        protected def clone
          self.class.new(
            children: @children.map { |c| c.clone.as(self) },
            connector: @connector,
            negated: @negated,
            predicates: @predicates.dup
          )
        end

        protected def to_sql(connection : Connection::Base)
          sql_parts = [] of String
          sql_params = [] of Field::Any

          @predicates.each do |predicate|
            predicate_sql, predicate_params = predicate.to_sql(connection)
            sql_parts << predicate_sql
            sql_params.concat(predicate_params)
          end

          @children.each do |child|
            child_sql, child_params = child.to_sql(connection)
            sql_parts << child_sql
            sql_params.concat(child_params)
          end

          sql_string = sql_parts.join(" #{@connector} ")

          unless sql_string.empty?
            sql_string = "NOT (#{sql_string})" if @negated
            sql_string = "(#{sql_string})" if sql_parts.size > 1
          end

          { sql_string, sql_params }
        end
      end
    end
  end
end
