<?php

class AssignableField extends BaseField {

  static public $assets = [
    'js' => [
      'assignable.js'
    ],
    'css' => [
      'assignable.css'
    ]
  ];

  public function help() {
    return 'Click on a user to assign this topic to them or revert the assignment.';
  }

  public function content() {
    $uuid = $this->page->uuid()->value;

    $content = '<div data-page-uuid="' . $uuid . '" class="assignable-field"></div>';

    return $content;
  }

}
