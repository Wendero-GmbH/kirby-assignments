<?php 

return array(
  'title' => 'Users with incomplete assignments',
  'options' => array(
    array(
      'text' => 'Optional option',
      'icon' => 'pencil',
      'link' => 'link/to/option'
    )
  ),
  'html' => function() {
    $html = '<div class="overview-widget"></div>
             <script>PageList.widget();</script>';

    return $html;
  }  
);