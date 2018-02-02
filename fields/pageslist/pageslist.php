<?php

class PagesListField extends BaseField {

  public $help = '';

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

  public function content() {
    if (!($this->model instanceof \User)) {
      $content = parent::content();
      $content->text('Fields of this type can only be attached to users.');
      return $content;
    }

    $content = parent::content();
    $content->addClass('pages-list');

    $str = $content->toString();

    $str .= <<<HTML
<script>
  PageList.main("{$this->model->username}")("{$this->name}")();
</script>
HTML;

    return $str;
  }

  public function validate() {
    return true;
  }
}

