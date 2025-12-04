# frozen_string_literal: true

require 'test_helper'

class ScopeTest < ActiveSupport::TestCase
  def setup
    ScopedItem.delete_all
    ScopedItemHierarchy.delete_all
    MultiScopedItem.delete_all
  end

  def test_roots_with_single_scope
    root1 = ScopedItem.create!(name: 'root1', user_id: 1)
    root2 = ScopedItem.create!(name: 'root2', user_id: 1)
    root3 = ScopedItem.create!(name: 'root3', user_id: 2)

    scoped_roots = ScopedItem.roots.where(user_id: 1)
    assert_equal 2, scoped_roots.count
    assert_includes scoped_roots, root1
    assert_includes scoped_roots, root2
    refute_includes scoped_roots, root3
  end

  def test_roots_with_multiple_scope
    root1 = MultiScopedItem.create!(name: 'root1', user_id: 1, group_id: 10)
    root2 = MultiScopedItem.create!(name: 'root2', user_id: 1, group_id: 10)
    root3 = MultiScopedItem.create!(name: 'root3', user_id: 1, group_id: 20)
    root4 = MultiScopedItem.create!(name: 'root4', user_id: 2, group_id: 10)

    scoped_roots = MultiScopedItem.roots.where(user_id: 1, group_id: 10)
    assert_equal 2, scoped_roots.count
    assert_includes scoped_roots, root1
    assert_includes scoped_roots, root2
    refute_includes scoped_roots, root3
    refute_includes scoped_roots, root4
  end

  def test_siblings_with_scope
    parent = ScopedItem.create!(name: 'parent', user_id: 1)
    child1 = parent.children.create!(name: 'child1', user_id: 1)
    child2 = parent.children.create!(name: 'child2', user_id: 1)
    child3 = parent.children.create!(name: 'child3', user_id: 2)

    siblings = child1.siblings
    assert_equal 1, siblings.count
    assert_includes siblings, child2
    refute_includes siblings, child3
  end

  def test_siblings_with_multiple_scope
    parent = MultiScopedItem.create!(name: 'parent', user_id: 1, group_id: 10)
    child1 = parent.children.create!(name: 'child1', user_id: 1, group_id: 10)
    child2 = parent.children.create!(name: 'child2', user_id: 1, group_id: 10)
    child3 = parent.children.create!(name: 'child3', user_id: 1, group_id: 20)
    child4 = parent.children.create!(name: 'child4', user_id: 2, group_id: 10)

    siblings = child1.siblings
    assert_equal 1, siblings.count
    assert_includes siblings, child2
    refute_includes siblings, child3
    refute_includes siblings, child4
  end

  def test_reordering_siblings_with_scope
    parent = ScopedItem.create!(name: 'parent', user_id: 1)
    child1 = parent.children.create!(name: 'child1', user_id: 1)
    child2 = parent.children.create!(name: 'child2', user_id: 1)
    child3 = parent.children.create!(name: 'child3', user_id: 2)

    child1._ct_reorder_siblings

    child1.reload
    child2.reload
    child3.reload

    assert_equal 0, child1.order_value
    assert_equal 1, child2.order_value
    assert_equal 0, child3.order_value
  end

  def test_reordering_siblings_with_multiple_scope
    parent = MultiScopedItem.create!(name: 'parent', user_id: 1, group_id: 10)
    child1 = parent.children.create!(name: 'child1', user_id: 1, group_id: 10)
    child2 = parent.children.create!(name: 'child2', user_id: 1, group_id: 10)
    child3 = parent.children.create!(name: 'child3', user_id: 1, group_id: 20)
    child4 = parent.children.create!(name: 'child4', user_id: 2, group_id: 10)

    child1._ct_reorder_siblings

    child1.reload
    child2.reload
    child3.reload
    child4.reload

    assert_equal 0, child1.order_value
    assert_equal 1, child2.order_value
    assert_equal 0, child3.order_value
    assert_equal 0, child4.order_value
  end

  def test_reordering_children_with_scope
    parent1 = ScopedItem.create!(name: 'parent1', user_id: 1)
    parent2 = ScopedItem.create!(name: 'parent2', user_id: 2)

    child1 = parent1.children.create!(name: 'child1', user_id: 1)
    child2 = parent1.children.create!(name: 'child2', user_id: 1)
    child3 = parent1.children.create!(name: 'child3', user_id: 1)

    parent1._ct_reorder_children

    child1.reload
    child2.reload
    child3.reload

    assert_equal 0, child1.order_value
    assert_equal 1, child2.order_value
    assert_equal 2, child3.order_value
  end

  def test_reordering_children_with_multiple_scope
    parent1 = MultiScopedItem.create!(name: 'parent1', user_id: 1, group_id: 10)
    parent2 = MultiScopedItem.create!(name: 'parent2', user_id: 1, group_id: 20)

    child1 = parent1.children.create!(name: 'child1', user_id: 1, group_id: 10)
    child2 = parent1.children.create!(name: 'child2', user_id: 1, group_id: 10)
    child3 = parent1.children.create!(name: 'child3', user_id: 1, group_id: 20)
    child4 = parent1.children.create!(name: 'child4', user_id: 2, group_id: 10)

    parent1._ct_reorder_children

    child1.reload
    child2.reload
    child3.reload
    child4.reload

    assert_equal 0, child1.order_value
    assert_equal 1, child2.order_value
    assert_equal 0, child3.order_value
    assert_equal 0, child4.order_value
  end

  def test_reordering_children_excludes_different_scope
    parent1 = ScopedItem.create!(name: 'parent1', user_id: 1)

    child1 = parent1.children.create!(name: 'child1', user_id: 1)
    child2 = parent1.children.create!(name: 'child2', user_id: 1)
    child3 = parent1.children.create!(name: 'child3', user_id: 2)

    initial_order = child3.order_value

    parent1._ct_reorder_children

    child1.reload
    child2.reload
    child3.reload

    assert_equal 0, child1.order_value
    assert_equal 1, child2.order_value
    assert_equal initial_order, child3.order_value, 'child3 with different scope should not be reordered'
  end

  def test_scope_values_from_instance
    instance = ScopedItem.new(user_id: 123)
    scope_values = instance._ct.scope_values_from_instance(instance)
    assert_equal({ user_id: 123 }, scope_values)
  end

  def test_scope_values_from_instance_multiple_columns
    instance = MultiScopedItem.new(user_id: 123, group_id: 456)
    scope_values = instance._ct.scope_values_from_instance(instance)
    assert_equal({ user_id: 123, group_id: 456 }, scope_values)
  end

  def test_scope_columns_method
    assert_equal [:user_id], ScopedItem._ct.scope_columns
    assert_equal [:user_id, :group_id], MultiScopedItem._ct.scope_columns
  end

  def test_updating_scope_attribute_rebuilds_tree
    parent = ScopedItem.create!(name: 'parent', user_id: 1)
    child = parent.children.create!(name: 'child', user_id: 1)
    grandchild = child.children.create!(name: 'grandchild', user_id: 1)

    # Verify initial tree structure
    assert_equal parent, child.parent
    assert_equal 2, parent.descendant_ids.count
    assert_includes parent.descendant_ids, child.id
    assert_includes parent.descendant_ids, grandchild.id

    # Update scope attribute
    child.update!(user_id: 2)

    # Reload to get fresh data
    parent.reload
    child.reload
    grandchild.reload

    # Child should now be in a different scope tree
    assert_nil child.parent
    assert_equal 1, parent.descendant_ids.count
    assert_includes parent.descendant_ids, grandchild.id
    refute_includes parent.descendant_ids, child.id

    # Child should be a root in the new scope
    assert child.root?
  end

  def test_updating_multiple_scope_attributes_rebuilds_tree
    parent = MultiScopedItem.create!(name: 'parent', user_id: 1, group_id: 10)
    child = parent.children.create!(name: 'child', user_id: 1, group_id: 10)
    grandchild = child.children.create!(name: 'grandchild', user_id: 1, group_id: 10)

    # Verify initial tree structure
    assert_equal parent, child.parent
    assert_equal 2, parent.descendant_ids.count
    assert_includes parent.descendant_ids, child.id
    assert_includes parent.descendant_ids, grandchild.id

    # Update one scope attribute
    child.update!(user_id: 2)

    parent.reload
    child.reload
    grandchild.reload

    # Child should now be in a different scope tree
    assert_nil child.parent
    assert child.root?
    assert_equal 1, parent.descendant_ids.count
    refute_includes parent.descendant_ids, child.id

    # Reset for next test
    child.update!(user_id: 1, parent_id: parent.id)
    child.reload
    parent.reload

    # Update the other scope attribute
    child.update!(group_id: 20)

    parent.reload
    child.reload

    # Child should again be in a different scope tree
    assert_nil child.parent
    assert child.root?
  end

  def test_scope_change_maintains_order_values
    parent = ScopedItem.create!(name: 'parent', user_id: 1)
    child1 = parent.children.create!(name: 'child1', user_id: 1)
    child2 = parent.children.create!(name: 'child2', user_id: 1)
    child3 = parent.children.create!(name: 'child3', user_id: 1)

    # Verify initial order
    assert_equal 0, child1.order_value
    assert_equal 1, child2.order_value
    assert_equal 2, child3.order_value

    # Change scope of middle child
    child2.update!(user_id: 2)

    child1.reload
    child2.reload
    child3.reload
    parent.reload

    # Remaining siblings should be reordered
    assert_equal 0, child1.order_value
    assert_equal 1, child3.order_value

    # Moved child should have its own order in new scope
    assert_equal 0, child2.order_value
  end
end

