<?php
/**
 * Created by PhpStorm.
 * User: �����
 * Date: 08.10.15
 * Time: 23:55
 */
namespace Orion\controllers\main\services;
class Template
{
    /**
     * Parses file, containing template, into string
     * @param $content_file name of template in TEMPLATE_ROOT directory
     * @param array|null $data key => value array to setup variables during parse
     * @return string
     */
    function parse($content_file, array $data = null)
    {
        if(is_array($data)) {
            extract($data, EXTR_OVERWRITE | EXTR_PREFIX_ALL, TEMPLATE_VAR_PREFIX);
        }
        ob_start();
        include TEMPLATE_ROOT . "/" . $content_file;
        return ob_get_clean();
    }
}
