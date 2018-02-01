<?php

class PagesListField extends BaseField {


  static public $assets = array(
    'js' => array(
      'dist.js'
    ),
    'css' => array(
      'structure.css'
    )
  );

  public function __construct() {
    $this->type        = 'pageslist';
    $this->label       = l::get('fields.number.label', 'Number');
    $this->placeholder = l::get('fields.number.placeholder', '#');
    $this->step        = 1;
    $this->min         = false;
    $this->max         = false;
  }

  
  public function input() {
    $input = parent::input();
    return $input;
  }

  public function content() {
    $content = parent::content();
    $content->addClass('pages-list');

    $str = $content->toString();

    $str .= js('/assets/js/pagelist.js');

    $str .= '<style type="text/css">.active { color: green; }</style>';

    //$content .= css('/panel/assets/css/pagelist.css');

    return $str;
  }

  public function validate() {

    return true;

  }

}

