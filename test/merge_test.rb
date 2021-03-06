require "test_helper"

# class PlanTest < Minitest::Spec
#   Plan()
#   add id: "a", Output(..) => Path().. # could we update the adds directly or do we have to go via the DSL here?
# end

class MergeTest < Minitest::Spec
  it do
    activity = Module.new do
      extend Activity::Path()

      task task: :a, id: "a"
    end

    merged = Module.new do
      extend Activity::Path::Plan()

      task task: :b, before: "a"
      task task: :c
    end

    # pp activity+merged
    _activity = Activity::Path::Plan.merge!(activity, merged)

    # the existing activity gets extended.
    activity.must_equal _activity

    Cct(activity.to_h[:circuit]).must_equal %{
#<Start/:default>
 {Trailblazer::Activity::Right} => :b
:b
 {Trailblazer::Activity::Right} => :a
 {Trailblazer::Activity::Left} => :a
:a
 {Trailblazer::Activity::Right} => :c
 {Trailblazer::Activity::Left} => :c
:c
 {Trailblazer::Activity::Right} => #<End/:success>
 {Trailblazer::Activity::Left} => #<End/:success>
#<End/:success>
}
  end

  describe "Activity.merge" do
    it "creates a new module without mutating shared state" do
      activity = Module.new do
        extend Activity::Path()

        task task: :a, id: "a"
      end

      plan = Module.new do
        extend Activity::Path::Plan()

        task task: :b, before: "a"
        task task: :c
      end

      merged = Activity::Path::Plan.merge(activity, plan)

      # activity still has one step
      Cct(activity.to_h[:circuit]).must_equal %{
#<Start/:default>
 {Trailblazer::Activity::Right} => :a
:a
 {Trailblazer::Activity::Right} => #<End/:success>
 {Trailblazer::Activity::Left} => #<End/:success>
#<End/:success>
}

      Cct(merged.to_h[:circuit]).must_equal %{
#<Start/:default>
 {Trailblazer::Activity::Right} => :b
:b
 {Trailblazer::Activity::Right} => :a
 {Trailblazer::Activity::Left} => :a
:a
 {Trailblazer::Activity::Right} => :c
 {Trailblazer::Activity::Left} => :c
:c
 {Trailblazer::Activity::Right} => #<End/:success>
 {Trailblazer::Activity::Left} => #<End/:success>
#<End/:success>
}
    end

    # TODO: test @options.frozen?
  end

  describe "Activity#merge" do
    it "what" do
      activity = Module.new do
        extend Trailblazer::Activity::Path()

        task task: :a
        task task: :b, id: "B", Output(false, :failure) => Path(end_semantic: :false) do
          task task: :d
        end
      end

      merging = Module.new do
        extend Trailblazer::Activity::Path()

        task task: :c

        merge! activity
      end

      Cct(merging.to_h[:circuit]).must_equal %{
#<Start/:default>
 {Trailblazer::Activity::Right} => :c
:c
 {Trailblazer::Activity::Right} => :a
 {Trailblazer::Activity::Left} => :a
:a
 {Trailblazer::Activity::Right} => :b
 {Trailblazer::Activity::Left} => :b
:b
 {false} => :d
 {Trailblazer::Activity::Right} => #<End/:success>
:d
 {Trailblazer::Activity::Right} => #<End/:false>
 {Trailblazer::Activity::Left} => #<End/:false>
#<End/:success>

#<End/:false>
}
    end

  end
end
