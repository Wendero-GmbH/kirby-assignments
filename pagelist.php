<?php

namespace Pagelist;

/**
 * @param \User $user
 * @param string $field
 * @param \Page $page
 */
function add(\User $user, $field, \Page $page) {
  if (!is_string($field)) { throw new Exception(); }

  $copy = $user->$field;
  
  if (!is_array($copy)) {
    $copy = [];
  }

  $i = array_search($page->uuid()->value, $copy);

  if (false === $i) {
    array_push($copy, $page->uuid()->value);
    $user->update([
      $field => $copy
    ]);
  }
}

/**
 * @param \User $user
 * @param string $field
 * @param \Page $page
 */
function remove(\User $user, $field, \Page $page) {
  if (!is_string($field)) { throw new Exception(); }

  $copy = $user->$field;
  $i = array_search($page->uuid()->value, $copy);

  if (is_int($i)) {

    unset($copy[$i]);
    $user->update([
      $field => $copy
    ]);
  }
}

/**
 * @param \User $user
 * @param string $field
 * @param \Page $page
 * @return bool
 */
function has(\User $user, $field, \Page $page) {
  if (!is_string($field)) { throw new Exception(); }

  return is_array($user->$field) &&
    in_array($page->uuid()->value, $user->$field);
}

/**
 * Returns all pages referenced in the given field as Page objects.
 * @param \User $user
 * @param string $field
 * @return array
 */
function all(\User $user, $field) {
  return array_map('get_page_by_uuid', $user->$field);
}

/**
 * @param \User $user
 * @param string $field
 * @return int
 */
function count(\User $user, $field) {
 if (!is_array($user->$field)) {
    return 0;
  }
  else {
    return size($user->$field);
  }
}

function ids(\User $user, $field) {
  if (!is_array($user->$field)) {
    return [];
  }

  return $user->$field;
}