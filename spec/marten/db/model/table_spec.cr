require "./spec_helper"

describe Marten::DB::Model::Table do
  describe "::db_table" do
    it "returns the name of the model table based on the class name by default" do
      TestUser.db_table.should eq "app_test_users"
    end

    it "does not append a s characters if model names already end by one" do
      PostTags.db_table.should eq "app_post_tags"
    end

    it "returns the configured table name if applicable" do
      Post.db_table.should eq "posts"
    end
  end

  describe "::db_table(name)" do
    it "allows to configure the model table name" do
      Post.db_table.should eq "posts"
    end
  end

  describe "::db_unique_constraint" do
    it "allows to configure new unique constraints" do
      unique_constraints = Post.db_unique_constraints
      unique_constraints.size.should eq 1
      unique_constraints[0].name.should eq "author_title"
      unique_constraints[0].fields.size.should eq 2
      unique_constraints[0].fields[0].id.should eq "author_id"
      unique_constraints[0].fields[1].id.should eq "title"
    end

    it "raises if the passed field does not correspond to any of the model's fields" do
      expect_raises(
        Marten::DB::Errors::UnknownField,
        "Unknown field 'unknown' in unique constraint definition"
      ) do
        Post.db_unique_constraint("new_unique", ["unknown", "author"])
      end
    end
  end

  describe "::db_unique_constraints" do
    it "returns an empty array if no unique constraints are defined" do
      TestUser.db_unique_constraints.should be_empty
    end

    it "returns an array of the configured unique constraints when unique constraints are defined" do
      unique_constraints = Post.db_unique_constraints
      unique_constraints.size.should eq 1
      unique_constraints[0].name.should eq "author_title"
      unique_constraints[0].fields.size.should eq 2
      unique_constraints[0].fields[0].id.should eq "author_id"
      unique_constraints[0].fields[1].id.should eq "title"
    end
  end

  describe "::fields" do
    it "returns the field instances associated with the considered model class" do
      Tag.fields.size.should eq 3
      Tag.fields.map(&.id).should eq ["id", "name", "is_active"]
    end
  end

  describe "::get_field" do
    it "allows to retrieve a specific model fields from an ID string" do
      field = Tag.get_field("name")
      field.should be_a Marten::DB::Field::String
      field.id.should eq "name"
    end

    it "allows to retrieve a specific model fields from an ID symbol" do
      field = Tag.get_field(:name)
      field.should be_a Marten::DB::Field::String
      field.id.should eq "name"
    end

    it "allows to retrieve a specific model fields from a relation name" do
      field = Post.get_field(:author)
      field.should be_a Marten::DB::Field::ManyToOne
      field.id.should eq "author_id"
    end

    it "raises if the field cannot be found" do
      expect_raises(Marten::DB::Errors::UnknownField) do
        Tag.get_field(:unknown)
      end
    end
  end

  describe "#get_field_value" do
    it "returns the value of a specific model instance field" do
      tag = Tag.new(name: "crystal")
      tag.get_field_value("name").should eq "crystal"
    end

    it "can support field names expressed as symbols" do
      tag = Tag.new(name: "crystal")
      tag.get_field_value(:name).should eq "crystal"
    end

    it "raises if the field cannot be found" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnknownField) do
        tag.get_field_value(:unknown)
      end
    end
  end

  describe "#set_field_value" do
    it "allows to set the value of a specific model instance field" do
      tag = Tag.new(name: "crystal")
      tag.set_field_value("name", "ruby")
      tag.name.should eq "ruby"
    end

    it "can support field names expressed as symbols" do
      tag = Tag.new(name: "crystal")
      tag.set_field_value(:name, "ruby")
      tag.name.should eq "ruby"
    end

    it "raises if the field cannot be found" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnknownField) do
        tag.set_field_value(:unknown, "test")
      end
    end

    it "raises if the value type is invalid for the considered field type" do
      tag = Tag.new(name: "crystal")

      expect_raises(Marten::DB::Errors::UnexpectedFieldValue) do
        tag.set_field_value(:name, 42)
      end
    end
  end

  describe "#to_s" do
    it "returns the expected model instance representation" do
      tag = Tag.create!(name: "crystal", is_active: true)
      tag.to_s.should eq "#<Tag:0x#{tag.object_id.to_s(16)} id: #{tag.id}, name: \"crystal\", is_active: true>"
    end
  end

  describe "#inspect" do
    it "returns the expected model instance representation" do
      tag = Tag.create!(name: "crystal", is_active: true)
      tag.inspect.should eq "#<Tag:0x#{tag.object_id.to_s(16)} id: #{tag.id}, name: \"crystal\", is_active: true>"
    end
  end
end
