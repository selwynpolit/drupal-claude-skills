# General (misc snippets)

**Source**: [Drupal at Your Fingertips - general](https://drupalatyourfingertips.com/general)
**Author**: Selwyn Polit

A grab-bag of one-off Drupal snippets that don't fit a single topic. The more broadly useful sections from this chapter were moved into focused reference files: current-context/routing helpers are in `routes.md`, preprocess/theming snippets are in `twig.md`, permissions/.htaccess snippets are in `security.md`, the Config Split walkthrough is in the `drupal-config-mgmt` skill, and the Solr query/document alteration snippets are in the `drupal-search-api` skill. What's left here didn't have a clear existing home.

---

## Get the path to the public directory

To get the path to the public directory, you can use the file system service. This is useful for accessing files stored there.

```php
$public_path = \Drupal::service('file_system')->realpath('public://');
```


## Check if the site is in system maintenance mode

```php
$is_maint_mode = \Drupal::state()->get('system.maintenance_mode');
```

## Convert TranslatableMarkup to a string

To convert a TranslatableMarkup object to a string, use either the `render()` or __toString() method. This example shows the values array with an element 'save' which is a TranslatableMarkup object.  These will return `Save Citation`.

![TranslatableMarkup](/images/translatable-markup.png)

```php
$values['save']->render();
// Or.
$values['save']->__toString();
```


## How to check whether a module is installed or not

```php
$moduleHandler = \Drupal::service('module_handler');
$module_name = “views”;
if ($moduleHandler->moduleExists($module_name)) {
  echo "$module_name installed";
}
else {
  echo "$module_name not installed";
}
```

## Remote media entities

For this project, I had to figure out a way to make media entities that really were remote images. i.e. the API provided images but we didn't want to store them in Drupal

I started by looking at <https://www.drupal.org/sandbox/nickhope/3001154> which was based on <https://www.drupal.org/project/media_entity_flickr>.

I tweaked the NickHope module (media_entity_remote_file) so it worked but it had some trouble with image styles and thumbnails

A good solution (thanks to Hugo) is:

https://www.drupal.org/project/remote_stream_wrapper_widget

https://www.drupal.org/project/remote_stream_wrapper

Hugo suggests using this to do migration:

```php
$uri = 'http://example.com/somefile.mp3';
$file = File::Create(['uri' => $uri]);
$file->save();
$node->field_file->setValue(['target_id' => $file->id()]);
$node->save();
```

There was no documentation so I [added some](https://www.drupal.org/project/remote_stream_wrapper/issues/2875444#comment-12881516).

## Deprecated functions like drupal_set_message

:::tip Note
`drupal_set_message()` has been removed from the codebase, so you should use `messenger()` but you can also use `dsm()` which is provided by the [devel](https://www.drupal.org/project/devel) contrib module. This is useful when working through a problem if you want to display a message on a site during debugging.
:::

From <https://github.com/mglaman/drupal-check/wiki/Deprecation-Error-Solutions>

Before

```php
drupal_set_message($message, $type, $repeat);
```

After

```php
\Drupal::messenger()->addMessage($message, $type, $repeat);
```

[Read more](https://www.drupal.org/node/2774931).

## Using the file_system service to count files

```php
// In the create method get the file_system service.
$form->fileSystem = $container->get('file_system');

// Search filesystem recursively get all .PHP files from Drupal's core folder.
$files_count = count($this->fileSystem->scanDirectory('core', '/.php/'));

```
See this in action in the [examples module](https://www.drupal.org/project/examples) in `CacheExampleForm.php`.


## Multiple authors on a node

Thanks to Mike Anello of [DrupalEasy for this useful solution.](https://www.drupaleasy.com/blogs/ultimike/2023/02/method-utilizing-multiple-authors-single-drupal-node)

**TL;DR**
Using the [Access by Reference module](https://www.drupal.org/project/access_by_ref) allows you to specify additional authors via several methods. Mike prefers using a reference field for this purpose. He also wanted the "Additional authors" field to be listed in the "Authoring information" accordion of the standard Drupal node add/edit form. He created a very small custom Drupal module named `multiauthor` that implements a single Drupal hook:

```php
/**
 * Implements hook_form_alter().
 */
function multiauthor_form_alter(array &$form, FormStateInterface $form_state, string $form_id): void {
  if (in_array($form_id, ['node_page_edit_form', 'node_page_form'])) {
    $form['field_additional_authors']['#group'] = 'author';
  }
}
```

This hook alters the Basic page add and edit forms, setting my custom "Additional author" field (field_additional_authors) to the "author" group in the "Additional authors" accordion. Users added to the `Additional authors` field get the same read, update, and delete permissions at the owner of the node.

## Calculating, displaying and logging elapsed time

To record how long something takes in Drupal, use the `Timer` utility class. In the example below, this info is also logged to the `watchdog` log.

In your config or `settings.local.php` (to temporarily override that value) you can enable or disable the timer with:

```php
$config['tea_teks_srp.testing']['display_elapsed_time'] = TRUE;
$config['tea_teks_srp.testing']['log_elapsed_time'] = TRUE;
```

This example uses a form so this is the constructor:

```php
class SrpVoteOnCitationForm extends FormBase {

  protected bool $displayElapsedTime = FALSE;
  protected bool $logElapsedTime = FALSE;

  public function __construct(VotingProcessorInterface $votingProcessor) {
    $this->displayElapsedTime = \Drupal::config('tea_teks_srp.testing')->get('display_elapsed_time');
    $this->displayElapsedTime = \Drupal::config('tea_teks_srp.testing')->get('log_elapsed_time');

  }
```

In `submitForm()` we start the timer, do some work and then stop the timer and report the result like this:

```php
public function submitForm(array &$form, FormStateInterface $form_state) {
  $user_id = \Drupal::currentUser()->id();
  Timer::start('vote:voter_id:' . $user_id);

  $current_path = \Drupal::service('path.current')->getPath();
  if ($this->displayElapsedTime) {
    $msg = 'Voter: ' . number_format($user_id). ' Citation: ' . number_format($citation_nid) .' Vote: ' . strtolower($voting_action) . ' Url:' . $current_path ;
    \Drupal::messenger()->addMessage($msg);
  }
  if ($this->logElapsedTime) {
    \Drupal::logger('tea_teks_srp')->info($msg);
  }

  // do the work...

  $end_time_in_ms = Timer::read($timer_name);
  Timer::stop($timer_name);
  $end_time = number_format($end_time_in_ms / 1000, 4);
  $msg = ' Vote: ' . strtolower($voting_action) .' took ' . $end_time . 's' . ' Voter: ' . number_format($user_id) . ' Citation: ' . number_format($citation_nid);
  if ($this->displayElapsedTime) {
    // Display elapsed time message.
    \Drupal::messenger()->addMessage($msg);
  }
  if ($this->logElapsedTime) {
    // Log the elapsed time message to watchdog.
    \Drupal::logger('tea_teks_srp')->info($msg);
  }
  // ...
```

## Populate a select list with the options from a list field

When you need to build a form with a drop-down (select) list of the options, you can call this function to build the select options that are defined in a `list (text)` field. You just pass the entity type e.g. `node`, the bundle or content type e.g. `article`, and the `machine name` of the field. You get back a nice array for use in the select list.

Example of list (text) field:

![Field list options](/images/field_list_options2.png)

```php
public static function getSelectOptions(string $entity_type, string $bundle, string $field_name): array {
  $options_array = [];
  $definitions = \Drupal::service('entity_field.manager')->getFieldDefinitions($entity_type, $bundle);
  if (isset($definitions[$field_name])) {
    $options_array = $definitions[$field_name]->getSetting('allowed_values');
  }
  return $options_array;
}
```

Then, in our form, we pass those parameters to get the `$audience_select_options`:

```php
$audience_select_options = RetrievePublisherData::getSelectOptions('node', 'teks_pub_citation', 'field_tks_audience');
```

Then use the options to populate the form element `$form['audience']` like this:

```php
$form['audience'] = [
  '#type' => 'select',
  '#title' => t('Audience'),
  '#empty_value' => '',
  '#empty_option' => '- Select the Audience -',
  '#required' => TRUE,
  '#options' => $audience_select_options,
];
```

## Get the human-readable value from a list field

When you need to get the human-readable value from a `list (text)` field you can use this code:

call this function to build the select options that are defined in a `list (text)` field. You just pass the entity type e.g. `node`, the bundle or content type e.g. `article`, and the `machine name` of the field. You get back a nice array for use in the select list.

Example of list (text) field:

![Field list options](/images/field_list_options2.png)

This seems to be the simplest version:

```php
  public static function getListFieldHumanReadableValue(EntityInterface $entity, string $field_name, string $list_item_value): string {
    $allowed_values = $entity->$field_name->getSetting('allowed_values');
    $human_readable_value = $allowed_values[$list_item_value];
    return $human_readable_value;
  }

```

which is called like this:

```php
$human_readable_value = VotingUtility::getListFieldHumanReadableValue($program_node, 'field_srp_program_status', 'rereview_requested');
```

`$allowed values` show up in an indexed array like this:

![list allowed values](/images/list_text_allowed_values.png)

Some other variations are:

```php
  public static function getListFieldHumanReadableValue(EntityInterface $entity, string $field_name, string

    // Option 1.
    $field = $entity->$field_name;
    $human_readable_value = $field->getFieldDefinition()
      ->getFieldStorageDefinition()
      ->getOptionsProvider('value', $field->getEntity())->getPossibleOptions()[$list_item_value];
    return $human_readable_value;

    // Option 2.
    // E.g. 'node.article.field_foo'.
    $field_string = "node.teks_pub_program.$field_name";
    $field_storage_definition = FieldConfig::load($field_string)->getFieldStorageDefinition();
    $allowed_values = $field_storage_definition->getSettings()['allowed_values'];
    $human_readable_value = $allowed_values[$list_item_value];
    return $human_readable_value;

    // Option 3.
    // E.g. 'node.article.field_foo'.
    $field_string = "node.teks_pub_program.$field_name";
    $allowed_values = FieldConfig::load($field_string)->getFieldStorageDefinition()->getSettings()['allowed_values'];
    $human_readable_value = $allowed_values[$list_item_value];
    //$x = $entity->get($field_name)->view()[0]['#markup'];
    return $human_readable_value;
  }

```

## System.schema (module is missing from your site)

When running `drush updb`, if the system reports:

```
[notice] Module rules has an entry in the system.schema key/value storage, but is missing from your site. <a href="https://www.drupal.org/node/3137656">More information about this error</a>.
[notice] Module typed_data has an entry in the system.schema key/value storage, but is not installed. <a href="https://www.drupal.org/node/3137656">More information about this error</a>.
```

[From https://www.drupal.org/node/3137656](https://www.drupal.org/node/3137656)

In the database, there is a table called `key_value` with a field called `collection` that contains the value `system.schema` for some rows. The field `name` has the names of modules.

![Image of key_value table](/images/system_schema_rules.png)

To repair these sorts of errors, you must remove the orphaned entries from the `system.schema` key/value storage system. There is no UI for doing this. You can use drush to invoke a system service to manipulate the system.schema data in the `key_value` table. For example, to clean up these two errors:

```
Module my_already_removed_module has a schema in the key_value store, but is missing from your site.
Module update_test_0 has a schema in the key_value store, but is not installed.
```

You would need to run the following commands:

```
drush php-eval "\Drupal::keyValue('system.schema')->delete('my_already_removed_module');"
drush php-eval "\Drupal::keyValue('system.schema')->delete('update_test_0');"
```

This can be done using a `hook_update_n` in your `.module` file like this:

```php
/**
 * Remove the rules and typed_data key/value entries from the system.schema.
 */
function tea_teks_update_8001() {
  \Drupal::keyValue('system.schema')->delete('rules');
  \Drupal::keyValue('system.schema')->delete('typed_data');
}
```

Alternatively, adding the missing modules with `composer install`, enabling them and deploying everything to production. Then, disabling them properly, deploying that to production, then removing the modules with `composer remove` and deploying may also work. Of course, this method is a lot more work.

## Enable verbose display of warning and error messages

In `settings.php`, `settings.local.php` or `settings.ddev.php` make sure there is the following:

```php
// Enable verbose logging for errors.
// https://www.drupal.org/forum/support/post-installation/2018-07-18/enable-drupal-8-backend-errorlogdebugging-mode
$config['system.logging']['error_level'] = 'verbose';
```

Also, see [Enable verbose error logging for better backtracing and debugging - April 2023](https://www.drupal.org/docs/develop/development-tools/enable-verbose-error-logging-for-better-backtracing-and-debugging)

## Reinstall modules

During module development or upgrades, it can be really useful to quickly uninstall and reinstall modules. Luckily, the [devel module](https://www.drupal.org/project/devel) provides an easy way. Either navigate to `/devel/reinstall` or use the Druplicon menu option and select `development` and then click on `reinstall modules` You will need the [admin toolbar module](https://www.drupal.org/project/admin_toolbar) with its `admin toolbar extra tools` submodule enabled.

![Menu option to reinstall modules](/images/reinstall_modules.png)



## Uninstall modules

Sometimes during development, things go goofy and you need to uninstall a module. Hopefully, you can use the Drupal user interface (Extend, uninstall modules) or `drush pmu MODULENAME`.  If these fail, try:

```sh
drush eval "\$module_data = \Drupal::config('core.extension')->get('module'); unset(\$module_data['MODULENAME']); \Drupal::configFactory()->getEditable('core.extension')->set('module', \$module_data)->save();"

drush php-eval "\Drupal::keyValue('system.schema')->delete('MODULENAME');"
```
If you still have an error, you should clear the cache or rebuild the router:

```sh
drush cr
drush ev '\Drupal::service("router.builder")->rebuild();'
drush cc router (Drupal 9/10)
```

More [at this page on drupal.org](https://www.drupal.org/forum/support/post-installation/2019-10-15/how-to-uninstall-drupal-8-module-when-uninstall-page)



## View a node in JSON format

With the JSON:API and Serialization core modules enabled, simply navigate to any node and add `?_format=api_json` to the end of the URL. E.g. `https://d9book2.ddev.site/node/25?_format=api_json`

## Display a file instead of the node

In this case, the node has a file field `field_doc_file` and we want to display that file instead of the node. This code also checks the user's permissions and rather displays the node if the user has the `administer content` permission.


Here is the route event subscriber in `docroot/modules/custom/abc_document/abc_document.services.yml`:

```yaml
services:
  abc_document.route_subscriber:
    class: Drupal\abc_document\Routing\RouteSubscriber
    tags:
      - { name: event_subscriber }
```

Here is the Code for the Route subscriber at `docroot/modules/custom/abc_document/src/Routing/RouteSubscriber.php`:
```php
<?php

namespace Drupal\abc_document\Routing;

use Drupal\Core\Routing\RouteSubscriberBase;
use Symfony\Component\Routing\RouteCollection;

/**
 * Listens to the dynamic route events.
 */
class RouteSubscriber extends RouteSubscriberBase {

  /**
   * {@inheritdoc}
   */
  protected function alterRoutes(RouteCollection $collection) {
    // Replace the controller for the node canonical route.
    if ($route = $collection->get('entity.node.canonical')) {
      $route->setDefaults([
        '_controller' => '\Drupal\abc_document\Controller\NodeViewController::view',
      ]);
    }
  }

}
```
And finally, the controller in `docroot/modules/custom/abc_document/src/Controller/NodeViewController.php`:

```php
<?php

namespace Drupal\abc_document\Controller;

use Drupal\Core\Entity\EntityInterface;
use Drupal\Core\StreamWrapper\StreamWrapperManagerInterface;
use Drupal\file\FileInterface;
use Drupal\node\Controller\NodeViewController as NodeViewControllerBase;
use Symfony\Component\DependencyInjection\ContainerInterface;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

/**
 * Defines a controller to render a single node.
 */
class NodeViewController extends NodeViewControllerBase {

  /**
   * The current request.
   *
   * @var \Symfony\Component\HttpFoundation\Request
   */
  protected Request $request;

  /**
   * The stream wrapper manager.
   *
   * @var \Drupal\Core\StreamWrapper\StreamWrapperManagerInterface
   */
  protected StreamWrapperManagerInterface $streamWrapperManager;

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container) {
    $instance = parent::create($container);

    $instance->request = $container->get('request_stack')->getCurrentRequest();
    $instance->streamWrapperManager = $container->get('stream_wrapper_manager');

    return $instance;
  }

  /**
   * {@inheritdoc}
   */
  public function view(EntityInterface $node, $view_mode = 'full', $langcode = NULL) {

    $included_types = [
      'progress_report',
      'program',
      'products',
      'finance',
      'event',
      ];

    /** @var \Drupal\node\NodeInterface $node */
    $bundle = $node->bundle();
    if (!in_array($bundle, $included_types) || !$node->hasField('field_doc_file')) {
      return parent::view($node, $view_mode);
    }

    // Display the node if the user is an admin.
    if ($this->currentUser->hasPermission('administer content')
    ) {
      return parent::view($node, $view_mode);
    }

    // If the node has no file item.
    $file = $node->get('field_doc_file')->entity;
    if (!$file) {
      throw new NotFoundHttpException();
    }
    assert($file instanceof FileInterface);
    $uri = $file->getFileUri();
    $scheme = $this->streamWrapperManager::getScheme($uri);

    // If the file does not exist.
    if (!$this->streamWrapperManager->isValidScheme($scheme) || !is_file($uri)) {
      throw new NotFoundHttpException();
    }

    // Generate the response.
    $response = new BinaryFileResponse($uri, Response::HTTP_OK, [], $scheme !== 'private');
    if (!$response->headers->has('Content-Type')) {
      $response->headers->set('Content-Type', $file->getMimeType() ?: 'application/octet-stream');
    }

    return $response;
  }

}
```




## Drupal bootstrap process

The Drupal bootstrap process is a series of steps that Drupal goes through on every page request to initialize the necessary resources and environment. You should have this article ready for your next interview.

Here are the steps:

1. **Loading the autoloader:** The first step in the bootstrap process is to load the Composer-generated `autoloader`. This allows Drupal to use any classes defined in the codebase without explicitly requiring the files they're defined in.
1. **Reading settings:** Drupal reads the `settings.php` file which has configuration settings for the site, such as database connection information and various other settings.
1. **Initializing the service container:** Drupal initializes the [service container](services#service-container) which is responsible for managing Drupal services. The service definitions are stored in various `.services.yml` files throughout the codebase. Drupal's service container is built on top of the Symfony service container. Documentation on the structure of this file, special characters, optional dependencies, etc. can all be found in the [Symfony service container documentation](https://symfony.com/doc/6.3/service_container.html).
1. **Handling the request:** Drupal creates a [Request object](https://api.drupal.org/api/drupal/core%21lib%21Drupal.php/function/Drupal%3A%3Arequest/8.4.x) from the global PHP variables and passes it to the `HttpKernel` to handle. The `HttpKernel` is responsible for handling the request and returning a `Response`.
1. **Routing:** The `HttpKernel` uses the [Router service](https://git.drupalcode.org/project/drupal/-/blob/11.x/core/lib/Drupal/Core/Routing/RouteProvider.php?ref_type=heads) to match the request to a [route](routes#route). A route is a path that is defined for Drupal to return some sort of content on. The route defines a [controller](routes#controller) that should be used to generate the content for the page.
1. **Controller execution:** A method in the controller is then executed. This method generates the content for the page. It can return a [render array](render#overview) (which Drupal will turn into HTML), a [Response object](https://www.drupal.org/docs/drupal-apis/responses/responses-overview), or some other type of content that Drupal knows how to handle.
1. **Rendering:** If the controller returns a render array, Drupal will (via an `EventSubscriber` run it through the theme layer which renders it into HTML. This involves calling various hooks and alter functions to allow modules to modify the content.
1. **Returning the response:** Finally, the `HttpKernel` returns a [Response object](https://www.drupal.org/docs/drupal-apis/responses/responses-overview), which is then sent to the client.

## Using hook_help

Modules can have a hook_help to display help info from the `extend` page. This is a simple example from the [examples module](https://www.drupal.org/project/examples) that shows how to use `hook_help`:

```php
/**
 * Implements hook_help().
 *
 * When implementing a hook you should use the standard text "Implements
 * HOOK_NAME." as the docblock for the function. This is an indicator that
 * further documentation for the function parameters can be found in the
 * docblock for hook being implemented and reduces duplication.
 *
 * This function is an implementation of hook_help(). Following the naming
 * convention for hooks, the "hook_" in hook_help() has been replaced with the
 * short name of our module, "hooks_example_" resulting in a final function name
 * of hooks_example_help().
 */
function hooks_example_help($route_name, RouteMatchInterface $route_match) {
  switch ($route_name) {
    // For help overview pages we use the route help.page.$moduleName.
    case 'help.page.hooks_example':
      return '<p>' . t('This text is provided by the function <code>hooks_example_help()</code>, which is an implementation of <code>hook hook_help()</code>. To learn more about how this works checkout the code in <code>hooks_example.module</code>.') . '</p>';
  }
}
```

This version loads the help text from a file:

```php
/**
 * implement hook_help
 **/
function route_play_help($route, $help) {
  switch ($route) {
    case 'help.page.route_play':
      $file_contents = file_get_contents( dirname(__FILE__) . "/README.md");
      $cleaned_contents =  Drupal\Component\Utility\Html::escape($file_contents);
      // Add breaks so the text is not all on one line.
      $cleaned_contents = str_replace("\n", "<br>", $cleaned_contents);
      return $cleaned_contents;
}

```
And from the [workbench menu access module](https://www.drupal.org/project/workbench_menu_access), this version uses the [markdown module](https://www.drupal.org/project/markdown) to display a markdown file:

```php
/**
 * Help page text.
 *
 * @param string $route_name
 *   The route name.
 * @param \Drupal\Core\Routing\RouteMatchInterface $route_match
 *   The route matcher service.
 *
 * @return string
 *   An HTML string.
 */
function workbench_menu_access_help($route_name, RouteMatchInterface $route_match) {
  $output = '';
  switch ($route_name) {
    case 'help.page.workbench_menu_access':
      $readme = __DIR__ . '/README.md';
      $text = file_get_contents($readme);

      // If the Markdown module is installed, use it to render the README.
      if ($text !== FALSE && \Drupal::moduleHandler()->moduleExists('markdown') === TRUE) {
        $filter_manager = \Drupal::service('plugin.manager.filter');
        $settings = \Drupal::configFactory()->get('markdown.settings')->getRawData();
        $config = ['settings' => $settings];
        /** @var \Drupal\filter\Plugin\FilterInterface $filter */
        $filter = $filter_manager->createInstance('markdown', $config);
        $output = $filter->process($text, 'en');
      }
      // Else the Markdown module is not installed output the README as text.
      elseif ($text !== FALSE) {
        $output = '<pre>' . $text . '</pre>';
      }

      // Add a link to the Drupal.org project.
      $output .= '<p>';
      $output .= t('Visit the <a href=":project_link">Workbench Menu Access project page</a> on Drupal.org for more information.', [
        ':project_link' => 'https://www.drupal.org/project/workbench_menu_access',
      ]);
      $output .= '</p>';
      break;
  }

  return $output;
}
```

## Display a message after a module is installed

From [Menu custom access module](https://www.drupal.org/project/menu_custom_access) this code displays a message after the module is installed.  In `web/modules/contrib/menu_custom_access/menu_custom_access.install`:


```php

function menu_custom_access_install() {
  \Drupal::messenger()->addStatus(t("Menu Custom Access is now enabled"));
}
```

## Generate a Leaflet map with popups in a block

Using the [Leaflet module](https://www.drupal.org/project/leaflet), you can create a map with popups in a block. In `web/modules/custom/leafmap/src/Plugin/Block/LeafMapBlock.php`:

```php
<?php

namespace Drupal\leafmap\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;
use Drupal\leaflet\LeafletService;

/**
 * Provides a 'LeafMapBlock' block.
 *
 * @Block(
 *  id = "leaf_map_block",
 *  admin_label = @Translation("Leaf map block"),
 * )
 */
class LeafMapBlock extends BlockBase implements ContainerFactoryPluginInterface {

  /**
   * Drupal\leaflet\LeafletService definition.
   *
   * @var \Drupal\leaflet\LeafletService
   */
  protected $leafletService;

  /**
   * Constructs a new LeafMapBlock object.
   */
  public function __construct(array $configuration, $plugin_id, $plugin_definition, LeafletService $leaflet_service) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);
    $this->leafletService = $leaflet_service;
  }

  public static function create(ContainerInterface $container, array $configuration, $plugin_id, $plugin_definition) {
    return new static(
      $configuration,
      $plugin_id,
      $plugin_definition,
      $container->get('leaflet.service')
    );
  }

  /**
   * {@inheritdoc}
   */
  public function build() {
    $build = [];

// Define your points.
    $points = [
      ['lat' => 37.7749, 'lon' => -122.4194, 'city' => 'San Francisco', 'job' => 'Software Engineer'],
      ['lat' => 34.0522, 'lon' => -118.2437, 'city' => 'Los Angeles', 'job' => 'Data Analyst'],
      ['lat' => 36.746841, 'lon' => -119.772591, 'city' => 'Fresno', 'job' => 'Web Developer'],
      ['lat' => 30.2672, 'lon' => -97.7431, 'city' => 'Austin', 'job' => 'Software Engineer'],
      // Add more points as needed.
    ];

    // Convert points to features.
    $features = [];
    foreach ($points as $point) {
      $popupContent = $point['city'] . '<br>Lat: ' . $point['lat'] . '<br>Lon: ' . $point['lon'] . '<br>Job: ' . $point['job'];
      $features[] = [
        'type' => 'point',
        'lat' => $point['lat'],
        'lon' => $point['lon'],
        'popup' => [
          'value' => $popupContent,
          ],
      ];
    }

    // Create a map with the features.
    $map = leaflet_map_get_info('OSM Mapnik');

    // Add Clustering by enabling the Leaflet Markercluster module.
    $map['settings']['leaflet_markercluster']['control'] = TRUE;

    $build['map'] = $this->leafletService->leafletRenderMap($map, $features, '500px');

    // Attach the library.
    $build['#attached']['library'][] = 'leafmap/leaflet-popup';

    return $build;
  }

}
```

For styling the popups, in `web/modules/custom/leafmap/leafmap.libraries.yml` add:

```yaml
leaflet-popup:
  css:
    theme:
      css/leaflet-popup.css: {}
```

and the CSS file at `web/modules/custom/leafmap/css/leaflet-popup.css`:

```css
.leaflet-popup-content {
  color: #333;
  font-size: 24px;
  line-height: 1.5;
}
```

It should look like this:

![Leaflet map with popups](/images/leaf-map-block.png)


### Customize the map pointers

You can customize the map pointers by specifying a path to a local `.png` file or a remote file on a CDN. Then pass the `$icon` as one of the elements of the `$features` array. You can see how in this snippet from the `build()` function:

```php
    $icon = [
      // 'iconUrl' => 'https://cdn.rawgit.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
      //'iconUrl' => '/themes/custom/abcd/assets/img/usa-icons/api.svg',
      'iconUrl' => '/sites/default/files/icon-electric.png',
      'iconSize' => [25, 41],
      'iconAnchor' => [12, 41],
      'popupAnchor' => [1, -34],
      'shadowSize' => [41, 41],
      // shadowUrl: 'my-icon-shadow.png',
      // shadowRetinaUrl: 'my-icon-shadow@2x.png',
    ];

    $features[] = [
      'type' => 'point',
      'lat' => $lat,
      'lon' => $long,
      'popup' => [
        'value' => implode('<hr>', $popupContent),
        'options' => $this->configuration['popup_options'] ?? '{"maxWidth":"300","minWidth":"50", "autoPan": true}',
      ],
      'icon' => $icon,
    ];
```
## Overriding admin menu listing

In this instance, the requirement was to change the menu listing to only show menus that the user has access to. This is done by overriding the `MenuListBuilder` class. First, you have to change the handler class in a `hook_entity_type_alter()` in `abc_workbench.module`:

```php
/**
 * Implements hook_entity_type_alter().
 */
function abc_workbench_entity_type_alter(array &$entity_types) {
  $entity_types['menu']->setHandlerClass('list_builder', AbcWorkbenchMenuListBuilder::class);
}
```
Then define the `listbuilder` service in the `.services.yml` file: `docroot/modules/custom/abc_workbench/abc_workbench.services.yml`:

```yaml
  abc_workbench.menu_list_builder:
    class: Drupal\abc_workbench\AbcWorkbenchMenuListBuilder
    arguments: [ '@entity_type.manager', '@entity_type.manager' ]
    tags:
      - { name: entity_list_builder, entity_type: menu }
```

Then lastly, you create the `AbcWorkbenchMenuListBuilder` class in `docroot/modules/custom/abc_workbench/src/AbcWorkbenchMenuListBuilder.php`.  Note that you only have to implement the functions that you want to override. In this case, it was the `getEntityIds()` function which can leverage custom or additional functions to help filter the output.  In this case, it checks the user's access to the menu and only includes those menus that the user has access to.:

Here is the `getEntityIds()` function:

```php

  /**
   * {@inheritdoc}
   */
  protected function getEntityIds() {
    // Remove the limit from the parent.
    $this->limit = NULL;

    // Get all menus to check access.
    $query = $this->getStorage()->getQuery()->sort('label', 'ASC');
    $allMenus = $query->execute();
    $includeMenus = [];

    // Check access for each menu and identify which menus to include.
    foreach ($allMenus as $menu_id) {
      // Load the menu entity using the menu ID.
      $menu = $this->getStorage()->load($menu_id);
      if ($menu && $this->checkSections($menu, $this->currentUser)) {
        $includeMenus[] = $menu->id();
      }
    }

    // Include only the menus that have access.
    $query = $this->getStorage()->getQuery()
      ->condition('id', $includeMenus, 'IN')
      ->sort('label', 'ASC');

    return $query->execute();
  }
```

Also, for clarity, here is the `checkSections()` function that is called in the `getEntityIds()` function:

```php
/**
   * Check Menu access.
   *
   * @param \Drupal\Core\Entity\EntityInterface $menu
   *   The entity to check.
   * @param \Drupal\Core\Session\AccountInterface $account
   *   The account to check.
   *
   * @return bool
   *   TRUE if access is granted, FALSE otherwise.
   *
   * @throws \Drupal\Component\Plugin\Exception\InvalidPluginDefinitionException
   * @throws \Drupal\Component\Plugin\Exception\PluginNotFoundException
   */
  protected function checkSections(EntityInterface $menu, AccountInterface $account): bool {
    static $check;
    // Internal cache for performance.
    $key = $menu->id() . ':' . $account->id();
    if (!isset($check[$key])) {
      // By default, ignore menus that don't explicitly have permissions.
      $check[$key] = FALSE;
      // Check for admin role.
      if ($account->hasPermission('administer workbench menu access') || $account->hasPermission('bypass workbench access')) {
        return TRUE;
      }
      $config = $this->configFactory->get('workbench_menu_access.settings');
      $active = $config->get('access_scheme');
      $settings = $menu->getThirdPartySetting('workbench_menu_access', 'access_scheme');
      if (!is_null($active) && !is_null($settings)) {
        /** @var \Drupal\workbench_access\Entity\AccessSchemeInterface $scheme */
        $scheme = $this->entityTypeManager->getStorage('access_scheme')
          ->load($active);
        $user_sections = $this->userSectionStorage->getUserSections($scheme, $account);

        // Check children / parents.
        $check[$key] = $this->workbenchAccessManager::checkTree($scheme, $settings, $user_sections);
      }
    }
    return $check[$key];
  }
```

If you need to override the user entity listbuilder, check out [Overriding the User entity list_builder handler](https://drupal.stackexchange.com/questions/284599/overriding-the-user-entity-list-builder-handler)

- [EntityListBuilder API](https://api.drupal.org/api/drupal/core%21lib%21Drupal%21Core%21Entity%21EntityListBuilder.php/class/EntityListBuilder/10)
- [UserListBuilder API which extends EntityListBuilder](https://api.drupal.org/api/drupal/core%21modules%21user%21src%21UserListBuilder.php/class/UserListBuilder/10)
- [MenuListBuilder API which extends EntityListBuilder](https://api.drupal.org/api/drupal/core%21modules%21menu_ui%21src%21MenuListBuilder.php/class/MenuListBuilder/10)



## Troubleshoot memory problems

In some cases, where there are lots of `Node::load()`  or `Node::loadMultiple()` calls, you may run into `out of memory` errors. If increasing the memory limit in `php.ini` (e.g. `memory_limit = 1024M`) doesn't resolve this, you might try flushing the entity memory cache with:

```php
\Drupal::service('entity.memory_cache')->deleteAll();
```

There is also a [Memory limit Policy module](https://www.drupal.org/project/memory_limit_policy) that is worth checking out to override the default memory_limit for specific paths, roles etc.

You can use the `memory_get_usage()` function to see how much memory is being used. You can also use the `memory_get_peak_usage()` function to see the maximum amount of memory used during the script's execution.

```php
$mgu1 = round(memory_get_usage() / 1024 / 1024, 2) . ' MB';
$mgu2 = round(memory_get_usage(TRUE) / 1024 / 1024, 2) . ' MB';
$mgpu1 = round(memory_get_peak_usage() / 1024 / 1024, 2) . ' MB';
$mgpu2 = round(memory_get_peak_usage(TRUE) / 1024 / 1024, 2) . ' MB';
\Drupal::logger('tea_teks_srp')->info('Memory usage: ' . $mgu1 . ' ' . $mgu2 . ' Peak: ' . $mgpu1 . ' ' . $mgpu2);
```

It may be worth looking at the `getOptimalMemoryLimit()` and `setMemoryLimit()` functions in the [xmlsitemap](https://www.drupal.org/project/xmlsitemap) module.

```php
  public function getOptimalMemoryLimit() {
    $optimal_limit = &drupal_static(__FUNCTION__);
    if (!isset($optimal_limit)) {
      // Set the base memory amount from the provided core constant.
      $optimal_limit = Bytes::toNumber(\Drupal::MINIMUM_PHP_MEMORY_LIMIT);

      // Add memory based on the chunk size.
      $optimal_limit += xmlsitemap_get_chunk_size() * 500;

      // Add memory for storing the url aliases.
      if ($this->config->get('prefetch_aliases')) {
        $aliases = $this->connection->query("SELECT COUNT(id) FROM {path_alias}")->fetchField();
        $optimal_limit += $aliases * 250;
      }
    }
    return $optimal_limit;
  }

  /**
   * {@inheritdoc}
   */
  public function setMemoryLimit($new_limit = NULL) {
    $current_limit = @ini_get('memory_limit');
    if ($current_limit && $current_limit != -1) {
      if (!is_null($new_limit)) {
        $new_limit = $this->getOptimalMemoryLimit();
      }
      if (Bytes::toNumber($current_limit) < $new_limit) {
        return @ini_set('memory_limit', $new_limit);
      }
    }
  }
```
The [full source code for the module is here](https://git.drupalcode.org/project/xmlsitemap).



Down the rabbit hole:
- [Changing PHP memory limits - May 2022](https://www.drupal.org/docs/7/managing-site-performance-and-scalability/changing-php-memory-limits)
- [memory_get_usage()](https://www.php.net/manual/en/function.memory-get-usage.php)
- [memory_get_peak_usage()](https://www.php.net/manual/en/function.memory-get-peak-usage.php)
- [EntityMemoryCache](https://api.drupal.org/api/drupal/core%21lib%21Drupal%21Core%21Entity%21EntityMemoryCache.php/class/EntityMemoryCache/8.9.x)
- [gc_collect_cycles - Forces collection of any existing garbage cycles](https://www.php.net/manual/en/function.gc-collect-cycles.php)
- [Collecting Cycles - reference counting memory mechanisms](https://www.php.net/manual/en/features.gc.collecting-cycles.php)



## Attach a library to all forms

Use `hook_form_alter()` to attach a custom library to all forms. This is useful when you want to include custom JavaScript or CSS files on all forms. In this example, the `abc_search` library is attached to all forms.

```php
/**
 * Implements hook_form_alter().
 */
function abc_search_form_alter(&$form, \Drupal\Core\Form\FormStateInterface $form_state, $form_id) {
  // Attach the custom library to all forms.
  $form['#attached']['library'][] = 'abc_search/abc_search';
```

## Cookie lifespan

Sometimes, security wants you to reduce the lifespan of cookies and, therefore, session.  Drupal has a default of 2,000,000 seconds (23 days) which means you will stay logged in for as long as 23 days. This can be a problem, especially on a shared computer. This can be tweaked to set it to 8 hours by adding  `sites/default/services.yml` with the following content:

```yaml
parameters:
  session.storage.options:
    # Default ini options for sessions.
    #
    # Some distributions of Linux (most notably Debian) ship their PHP
    # installations with garbage collection (gc) disabled. Since Drupal depends
    # on PHP's garbage collection for clearing sessions, ensure that garbage
    # collection occurs by using the most common settings.
    # @default 1
    gc_probability: 1
    # @default 100
    gc_divisor: 100
    #
    # Set session lifetime (in seconds), i.e. the grace period for session
    # data. Sessions are deleted by the session garbage collector after one
    # session lifetime has elapsed since the user's last visit. When a session
    # is deleted, authenticated users are logged out, and the contents of the
    # user's session is discarded.
    # @default 200000
    gc_maxlifetime: 28800
    #
    # Set session cookie lifetime (in seconds), i.e. the time from the session
    # is created to the cookie expires, i.e. when the browser is expected to
    # discard the cookie. The value 0 means "until the browser is closed".
    # @default 2000000
    cookie_lifetime: 28800
```
More at:
- [Drupal Tips: Changing session lifetime for users by David Rodriguez - Mar 2022](https://davidjguru.github.io/blog/drupal-tips-changing-session-lifetime-for-users)
- [Stack Exchange](https://drupal.stackexchange.com/questions/215622/how-do-i-set-the-cookie-lifetime)


## Custom module to search all pages for a string

This controller will search all pages by rendering them and report back if the string is found.  This is useful if you need to find a string in a page that is not easily found in the database.  This is a simple example of how to do this.

Here is the `page_search_utility.info.yml` file:

```yaml
name: 'Page search utility'
type: module
description: 'Page search utility.'
package: 'Custom'
core_version_requirement: ^10
```


This is a controller that can be accessed via a route.  The route is defined in the `page_search_utility.routing.yml` file:

```yaml
page_search_utility_search1:
  path: '/page-search/search1'
  defaults:
    _title: 'Page Search Utility'
    _controller: '\Drupal\page_search_utility\Controller\PageSearchUtilityController'
  requirements:
    _permission: 'access content'
```

Here is the controller in the `src/Controller/PageSearchUtilityController.php` file:

```php
<?php

declare(strict_types=1);

namespace Drupal\page_search_utility\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Database\Connection;

/**
 * Returns responses for Page search utility routes.
 */
final class PageSearchUtilityController extends ControllerBase {

  /**
   * Builds the response.
   */
  public function __invoke(): array {
    $string_to_find = 'abc.example.com';
    $connection = \Drupal::database();
    $build = [];
    $this->find_string_in_nodes($string_to_find, $connection, $build);

    $build['content'][] = [
      '#type' => 'item',
      '#markup' => $this->t('Finished'),
    ];

    return $build;
  }

  function find_string_in_nodes($string, Connection $connection, array &$build): void {
    // Create entity query to load all published nodes.
    $query = \Drupal::entityQuery('node');
    $query->condition('status', 1);
    $query->accessCheck(FALSE);
    $nids = $query->execute();
    $count = count($nids);

    // Show message indicating number of nodes to be processed.
    $build['content'][] = [
      '#title' => 'Search: ',
      '#type' => 'item',
      '#markup' => 'Processing ' . $count . ' nodes',
    ];

    foreach ($nids as $nid) {
      $node = \Drupal::entityTypeManager()->getStorage('node')->load($nid);
      // If node doesn't load, report the nid and continue.
      if (!$node) {
        $build['content'][] = [
          '#title' => 'Node Problem: ',
          '#type' => 'item',
          '#markup' => 'Node not loaded: ' . $nid,
        ];
        continue;
      }
      $nid = $node->id();
      $type = $node->bundle();
      $url = $node->toUrl();

      $renderer = \Drupal::service('renderer');
      $view_builder = \Drupal::entityTypeManager()->getViewBuilder('node');
      $render_array = $view_builder->view($node, 'full');
      $rendered_node = $renderer->render($render_array);

      if (str_contains($rendered_node->__toString(), $string)) {
        // print 'Found links to "' . $string . '" in node ' . $nid . PHP_EOL;
        //$result = 'Found links to "' . $string . '" in node ' . $nid . PHP_EOL;
        $result = 'Found link(s) to "' . $string . '" in node ' . $nid . ' of type ' . $type . PHP_EOL;
        $build['content'][] = [
          '#prefix' => '<div>',
          '#title' => $result,
          '#type' => 'link',
          '#url' => $url,
          '#suffix' => '</div>',
        ];
      }
    }
  }

}
```

Here is what the output looks like when it finds the string:

```
Processing nodes Processing 2790 nodes

Found links to "abc.example.com" in node 7
Found links to "abc.example.com" in node 8
Finished
```

There is also a [Find Text Module](https://www.drupal.org/project/find_text) that can be used to search for text in the site.

## Get the display name for a custom entity bundle

If you have created custom entities with bundles e.g. custom entities of type `hardware` with bundles: `nut`, `bolt`, `screw`, etc. and you want to get the display name for the bundle, you can use the following code. Note that the display name is customizable through the Drupal User Interface so users can customize it to make it more human-readable.

```php
$entity_id = 123;
$entity_type_id = 'hardware';
// Load the entity and get it's bundle machine name.
$entity = \Drupal::entityTypeManager()->getStorage($entity_type_id)->load($entity_id);
$bundle = $entity->bundle();

// Use the entity type bundle info service to get the bundle info.
$entity_type_bundle_info = \Drupal::service('entity_type.bundle.info');
$bundle_info = $entity_type_bundle_info->getBundleInfo($entity_type_id);
// Get the label for the bundle.
$bundle_label = $bundle_info[$bundle]['label'];
```

I used this in an implementation of `template_preprocess_views_view_field()` to get the display name of the bundle for a custom entity type to display in a view. For some strange reason, Drupal wouldn't display the bundle name for anonymous users even though they had access to the content.


## Figure out a file extension and display an icon

This is implemented in a `.theme` file. It does several things including trimming the body text, getting the topic area from a taxonomy term, and determining the type of toolkit item based on the file extension of either the link field (`field_link`) or the attachment field (`field_attachment`). It also sets an icon name based on the type of toolkit item.

```
/**
 * Implements hook_preprocess_node() for node templates.
 */
function uswds_base_abc_preprocess_node(&$variables): void {
  $view_mode = $variables['view_mode'];
  $node = $variables['node'];
  $node_type = '';
  $variables['node_type'] = '';
  if ($node) { // check we have a node object.
    $variables['nodeid'] = $node->id();
    $node_type = $node->getType();
  }
  if ($node_type != 'toolkit_item') {
    return;
  }
//  if ($view_mode != 'card') {
//    // Only process card view mode for toolkit_item nodes.
//    return;
//  }

  // Body processing.
  $variables['body'] = '';
  $body = $node->get('body')->getValue();
  if (!empty($body)) {
    $body = $body[0]['value'];
    // Limit the body text to 50 characters.
    if (strlen($body) > 60) {
      $body = substr($body, 0, 60) . '...';
    }
    $variables['body'] = $body;
  }

  // Process field_topic_area
  $variables['topic_area'] = '';
  $topic_area = $node->get('field_topic_area')->getValue();
  if (!empty($topic_area)) {
    // Lookup taxonomy term by ID.
    $term_storage = \Drupal::entityTypeManager()->getStorage('taxonomy_term');
    $term = $term_storage->load($topic_area[0]['target_id']);
    if ($term) {
      // Get the term name.
      $variables['topic_area'] = $term->getName();
    }
  }

  // Process link field.
  $toolkit_item_type = 'WEB';
  $variables['link'] = '';
  $link = $node->get('field_link')->getValue();
  if (!empty($link)) {
    $uri = $link[0]['uri'];
    $variables['link'] = $uri;
    if (str_contains($uri, '.pdf')) {
      $toolkit_item_type = 'PDF';
    }
    if (str_contains($uri, '.docx') || str_contains($uri, '.doc')) {
      $toolkit_item_type = 'DOC';
    }
    if (str_contains($uri, '.xlsx') || str_contains($uri, '.xls')) {
      $toolkit_item_type = 'XLS';
    }
  }

  // Process the attachment field.
  $variables['attachment'] = '';
  $attachment = $node->get('field_attachment')->getValue();
  if (!empty($attachment)) {
    $file = \Drupal::entityTypeManager()->getStorage('file')->load($attachment[0]['target_id']);
    $filename_with_path = $file->getFileUri();
    $filename = $file->getFilename();
    $variables['file'] = $filename_with_path;

    $file_extension = strtolower(substr($filename, -5));
    // check for pdf
    if (str_ends_with($file_extension, '.pdf')) {
      $toolkit_item_type = 'PDF';
    }
    // check for docx or doc
    if (str_ends_with($file_extension, '.docx') ||str_ends_with($file_extension, '.doc')) {
      $toolkit_item_type = 'DOC';
    }
    // check for xlsx or xls
    if (str_ends_with($file_extension, '.xlsx') || str_ends_with($file_extension, '.xls')) {
      $toolkit_item_type = 'XLS';
    }

//    $toolkit_item_type = strtoupper($file_extension);
    $variables['attachment'] = $filename;
  }

  // Figure out the icon based on the toolkit item type.
  switch($toolkit_item_type) {
    case 'PDF':
      $icon_name = 'pdf-icon.svg';
      break;
    case 'DOC':
      $icon_name = 'doc-icon.svg';
      break;
    case 'XLS':
      $icon_name = 'xls-icon.svg';
      break;
    default:
      $icon_name = 'web-icon.svg';
      break;
  }

  $variables['toolkit_item_type'] = $toolkit_item_type;
  $variables['icon_name'] = $icon_name;

}
```

Here is the twig template (`node--toolkit-item--card.html.twig`) that uses the variables set in the preprocess function:

```twig

  <div class="toolkit-card-item">
    <div class="usa-card__header">
      {% if file %}
        <a href="{{ file|file_url }}"  class=""><h3>{{ label }}</h3></a>
      {% endif %}

      {% if link %}
        <a href="{{ link }}" class=""><h3>{{ label }}</h3></a>
      {% endif %}
    </div>

    <div class="usa-card__body">
      {{ body|replace({'<p>':'', '</p>':''}) }}
      <div>{{ topic_area }}</div>
      <img class="toolkit-card-icon float-right"
           src="/sites/abc/themes/custom/uswds_base_abc/assets/img/{{ icon_name }}"
           alt="{{ icon_name }}"
           class="toolkit-card-icon">
    </div>
  </div>
```



## List enabled contrib modules for a site with drush

You can use drush to list enabled contrib modules for a site.

```sh
ddev drush pm:list --type=module --status=enabled --no-core --format=list | sort > /tmp/agov.txt
```

In a multisite, you might need to compare the enabled modules.  Here we list the enabled modules for the default and fai sites and then run a diff on them.

```sh
# Quick diff of enabled contrib modules:
drush -l default pm:list --type=module --status=enabled --no-core --format=list | sort > /tmp/agov.txt
drush -l fai  pm:list --type=module --status=enabled --no-core --format=list | sort > /tmp/fai.txt
diff -u /tmp/agov.txt /tmp/fai.txt
```


## Use git to figure out if a particular module was ever used on a project

Here I need to know if the "purge" module was ever used in the project.

```sh
git log -p -S "purge" -- composer.json
```

The output showing the `purge_queuer_url` was added on December 17, 2021 (by the famous Illya Kuryakinlooks something like:

```
commit 885cf9a4c3ed4d78ee28449624fe7794b5670f68
Author: Illya Kuryakin <illya.kuryakin@uncle.org>
Date:   Fri Dec 17 09:22:32 2021 -0500

    Add ccos and purger modules

diff --git a/drupal/composer.json b/drupal/composer.json
index bc205f7e9..6b7d3a093 100755
--- a/drupal/composer.json
+++ b/drupal/composer.json
@@ -46,6 +46,7 @@
         "drupal/autologout": "^1.3",
         "drupal/cas": "^1.7",
         "drupal/cas_attributes": "^2.0@beta",
+        "drupal/ccos": "^2.0",
         "drupal/coder": "^8.3",
         "drupal/config_split": "^1.7",
         "drupal/context": "^4.1",
@@ -79,6 +80,8 @@
         "drupal/pdf_api": "2.x-dev@dev",
         "drupal/phpmailer_smtp": "*",
         "drupal/printable": "^2.0",
+        "drupal/purge_queuer_url": "^1.0",
+        "drupal/queue_ui": "^2.2",
         "drupal/redirect": "^1.6",
         "drupal/rename_admin_paths": "^2.0",
```



## Sync files between servers with lsync daemon

The [lsync](https://github.com/lsyncd/lsyncd) daemon is a tool that can be used to synchronize files between two or more servers. It is similar to `rsync`, but it runs as a daemon and can be configured to automatically synchronize files at regular intervals. This can be useful for keeping files in sync between a primary and secondary server, such as in a load-balanced environment.

If you give lsync too large of a directory, it may fail. You can solve this by breaking up the tasks into smaller chunks.  Do this by creating separate `sync` sections. Lsync knows how to automatically execute each `sync` section without any additional configuration.

I was working on a project that was failing to sync the entire `/web/server1/html` directory due to the vast number of files and folders. The solution was to break it up into multiple `sync` sections, each handling a smaller chunk of the directory. In the example config file below, the `/web/server1/html` directory is broken up into multiple `sync` sections, each handling a different subdirectory.

:::tip Note
You have to restart the lsync daemon after making changes to the configuration file.  You can do this with `sudo systemctl restart lsyncd` or `sudo service lsyncd restart`.  You can also check the status of the daemon with `sudo systemctl status lsyncd` or `sudo service lsyncd status`. Check the logs in `/var/log/lsyncd/lsyncd.log` to see if there are any errors or issues with the synchronization.
:::

This partial configuration file should provide enough information to identify how to use it. It is stored in  `/etc/lsyncd.conf`. This instruction ` default.rsyncssh,` indicates that it will use `rsync` over SSH.  You can simply choose from a set of three default implementations which are: rsync, rsyncssh and direct.

The `source` is the source directory to be synchronized, and the `targetdir` is the target directory on the remote server.  The `host` is the remote server to synchronize with.  The `delay` is the time in seconds to wait before synchronizing.  The `rsync` options are passed to the `rsync` command.


```
----
-- User configuration file for lsyncd.
--
-- For more examples, see /usr/share/doc/lsyncd*/examples/
--
-- sync{default.rsyncssh, source="/var/www/html", host="localhost", targetdir=}

settings {
 logfile = "/var/log/lsyncd/lsyncd.log",
 statusFile = "/var/log/lsyncd/lsyncd.status",
 statusInterval = 20,
 insist = true,
}

-- Sync Configurations /web/server1/html/config/
sync {
 default.rsyncssh,
 source = "/web/server1/html/config/",
 host = "123.123.123.123",
 targetdir = "/web/server2/html/config/",
 delay = 5,

 rsync = {
   update=true,
   perms=true,
   executability=true,
   verbose=true,
   owner=true,
   group=true,
 }
}

-- Sync Patches /web/server1/html/patches/
sync {
  default.rsyncssh,
  source = "/web/server1/html/patches/",
  host = "123.123.123.123",
  targetdir = "/web/server2/html/patches/",
  delay = 5,

  rsync = {
    update=true,
    perms=true,
    executability=true,
    verbose=true,
    owner=true,
    group=true,
  }
}

-- Sync Vendor /web/server1/html/vendor/
sync {
  default.rsyncssh,
  source = "/web/server1/html/vendor/",
  host = "123.123.123.123",
  targetdir = "/web/server2/html/vendor/",
  delay = 5,

  rsync = {
    update=true,
    perms=true,
    executability=true,
    verbose=true,
    owner=true,
    group=true,
  }
}

-- Sync Vendor /web/server1/html/web/
-- Notice the exclude section
sync {
  default.rsyncssh,
  source = "/web/server1/html/web/",
  host = "123.123.123.123",
  targetdir = "/web/server2/html/web/",
  exclude = {
    '/web/server2/html/web/vendor/*',
    '/web/server2/html/web/sites/default/files/*',
    '/web/server2/html/web/sites/faq/files/*'
  },
  delay = 5,

  rsync = {
    update=true,
    perms=true,
    executability=true,
    verbose=true,
    owner=true,
    group=true,
  }
}


-- Sync files /web/server2/html/web/sites/default/files/
 sync {
  default.rsyncssh,
  source = "/web/server2/html/web/sites/default/files/",
  host = "123.123.123.123",
  targetdir = "/web/server2/html/web/sites/default/files/",
  delay = 5,

  rsync = {
    update=true,
    perms=true,
    executability=true,
    verbose=true,
    owner=true,
    group=true,
  }
 }
```

Here is an example of the command that would be run by the lsync daemon.  This is the command that would be run if you were to run it manually.  The `--delete` option will delete files on the target server that are not present on the source server.  The `--ignore-errors` option will ignore errors and continue with the synchronization.  The `-sEolvutpg` options are passed to the `rsync` command to control the synchronization process.

```sh
/usr/bin/rsync --delete --ignore-errors -sEolvutpg -r /web/server1/html/config/ 123.123.123.123:/web/server2.com/html/config
```

If you have 30GB of files in `sites/default/files`, you could logically break these into 3 tasks, each of which could handle 10GB of data.
```
/sites/default/files 30GB
/sites/default/files/2022 10GB
/sites/default/files/2023 10GB
```

you might create one `sync` section for the `sites/default/files` which represents 10 GB (excluding the `sites/default/files/2022` and `sites/default/files/2023`  directories) and then create another section for the `sites/default/files/2022` which represents another 10 GB and a third section for `sites/default/files/2023` which represents another 10 GB.


To ensure all required files are synced, identify a top-level directory such as `sites/default/files` and then exclude subdirectories (such as `sites/default/files/2022` and `sites/default/files/2023`) to logically give the sync process only as much work as it can handle.

You can use useful Linux utilities like `du` to identify the size of directories.  For example, to get the size of the `sites/default/files` directory, you could run:

```sh
 du -h --max-depth=1 /web/server1/html
```

It outputs something like:
```
 20M	./config
4.0K	./.lando
455M	./web
 60K	./patches
  0B	./.local
 25M	./node_modules
1.1M	./solr
 24K	./scripts
  0B	./modules
4.0K	./lando_config
402M	./vendor
 19G	.
```


:::tip Note
If you want to get really crazy, you can write scripts in the [Lua programming language](https://www.lua.org/home.html)
:::


### Bash script to check for lsyncd errors

This is a bash script that can be used to check for errors in the lsyncd log file.  It will check the log file for any errors and report them.  It will also check the number of lines in the log file and if it exceeds 21 lines, it will report that as an error. This is not a robust solution and is very specific to my implementation. You may need to modify it to suit your needs.

Use the command: `rsync --delete --ignore-errors -sEolvutpgnc -r $EXCLUDES "${SRC}/" "${DEST}/" > /tmp/rsync_output.log 2>&1` to run the rsync command and redirect the output to a log file. Note, replace the src and dest with real values (no double quotes or dollar signs needed). This will create a log file in `/tmp/rsync_output.log` that contains the output of the rsync command. If a filename is listed in the file, that means rsync has found a difference between the source and destination directories. No output means the directories are in sync.

Run wc to count the lines of the file with `wc -l < /tmp/rsync_output.log`.  You may need to add a file to the source directory and rerun to see the output.  Then you can update the script to check for the number of lines for your setup.

```bash
#!/bin/bash
# Validate that multiple source and destination directories are in sync using rsync over SSH.

# Define an array of source, destination, and exclude patterns.
# Format: "SRC1|DEST1|EXCLUDES1" "SRC2|DEST2|EXCLUDES2" ...
DIR_PAIRS=(
  "/web/server1/html/config/|123.123.123.123:/web/server2/html/config/"
  "/web/server1/html/vendor/|123.123.123.123:/web/server2/html/vendor/"
  "/web/server1/html/web/|123.123.123.123:/web/server2/html/web/|--exclude=vendor --exclude=sites/default/files --exclude=sites/fai/files"
  "/web/server1/html/web/vendor/|123.123.123.123:/web/server2/html/web/vendor/"
  "/web/server1/html/web/sites/default/files/|123.123.123.123:/web/server2/html/web/sites/default/files/|--exclude=agov_logs --exclude=current --exclude=archives –exclude=php"
  "/web/server1/html/web/sites/default/files/archives/|123.123.123.123:/web/server2/html/web/sites/default/files/archives/|--exclude=far --exclude=pdf --exclude=zip"
  "/web/server1/html/web/sites/default/files/archives/far/|123.123.123.123:/web/server2/html/web/sites/default/files/archives/far/"
  "/web/server1/html/web/sites/default/files/archives/pdf/|123.123.123.123:/web/server2/html/web/sites/default/files/archives/pdf/"
  "/web/server1/html/web/sites/default/files/archives/zip/|123.123.123.123:/web/server2/html/web/sites/default/files/archives/zip/"
  "/web/server1/html/web/sites/default/files/current/|123.123.123.123:/web/server2/html/web/sites/default/files/current/"
  "/web/server1/html/web/sites/default/files/agov_logs/|123.123.123.123:/web/server2/html/web/sites/default/files/agov_logs/"
  "/web/server1/html/web/sites/fai/files/|123.123.123.123:/web/server2/html/web/sites/fai/files/|--exclude=pdfs --exclude=direct"
  "/web/server1/html/web/sites/fai/files/pdfs/|123.123.123.123:/web/server2/html/web/sites/fai/files/pdfs/"
  "/web/server1/html/web/sites/fai/files/direct/|123.123.123.123:/web/server2/html/web/sites/fai/files/direct/"
  "/web/server1/html/|123.123.123.123:/web/server2/html/|--exclude=backups --exclude=config --exclude=configbck120624 --exclude=config_bkp --exclude=config_stage.zip --exclude=current --exclude=DATABASE_BACKUPS_FOR_A_FAI --exclude=database-starter.sql.gz --exclude=dita_tools --exclude=lando_config --exclude=my-php-policy.pp --exclude=my-php-policy.te --exclude=published --exclude=regulation --exclude=vendor --exclude=web"
)


# Loop through each pair and validate sync.
for PAIR in "${DIR_PAIRS[@]}"; do
  SRC=$(echo "$PAIR" | cut -d'|' -f1)
  DEST=$(echo "$PAIR" | cut -d'|' -f2)
  EXCLUDES=$(echo "$PAIR" | cut -d'|' -f3)


  echo "Validating sync from ${SRC} to ${DEST} using rsync in checksum dry-run mode with SSH..."


  # The options used:
  # --delete: Flag files in the destination that have been removed from the source
  # --ignore-errors: Continue syncing even if there are errors
  # -s: Handle spaces in file names
  # -E: Preserve executability
  # -o: Preserve owner
  # -l: Copy symlinks as symlinks
  # -v: Verbose output
  # -u: Skip files that are newer on the destination
  # -t: Preserve modification times
  # -p: Preserve permissions
  # -g: Preserve group
  # -n: Dry run (no changes made)
  # -r: Recursive
  # -c: Use checksum to determine if files are different
  rsync --delete --ignore-errors -sEolvutpgnc -r $EXCLUDES "${SRC}/" "${DEST}/" > /tmp/rsync_output.log 2>&1


  # Count the number of lines in the output log
  LINE_COUNT=$(wc -l < /tmp/rsync_output.log)

  # Check if the line count exceeds 21
  if [ "$LINE_COUNT" -gt 21 ]; then
    echo "Validation found differences or errors for ${SRC} -> ${DEST}:"
    cat /tmp/rsync_output.log
    exit 1
  else
    echo "Validation successful: All files are in sync for ${SRC} -> ${DEST}."
  fi
done

exit 0
```

## Broken Links

There is an interesting side effect of running wget in spider mode to crawl a website.  It will report back any broken links it finds.

```sh
wget -e robots=off -r -nd --delete-after -l100 --spider https://austinprogressivecalendar.com./
```


```
Found 28 broken links.

https://www.austinprogressivecalendar.com/sites/default/files/styles/huge/public/inserted-images/content_landod8_2019-02-0
8_13-23-14.png?itok=h9R-_TbV
https://www.austinprogressivecalendar.com/sites/default/files/styles/huge/public/inserted-images/800px-organic_mixed_beans
_shoots.jpg?itok=8Q1YBYMD
https://www.austinprogressivecalendar.com/sites/default/files/styles/medium/public/inserted-images/sprouting_mung_beans_in
_a_jar.jpg?itok=lEU7GrCU
https://www.austinprogressivecalendar.com/taxonomy/term/href
https://www.austinprogressivecalendar.com/sites/default/files/styles/huge/public/inserted-images/landod8_siteslandod8_-_.i
ndex_.php_landod8_2019-02-08_13-46-19.png?itok=p1pejLxz
https://www.austinprogressivecalendar.com/sites/default/files/styles/medium/public/inserted-images/avgpic1.png?itok=u7PEc3
R9
https://www.austinprogressivecalendar.com/sites/default/files/imce_images/small_event_-_d7.austexcs.com_1294758758267.png
https://www.austinprogressivecalendar.com/sites/default/files/styles/large/public/inserted-images/win8.jpg
https://www.austinprogressivecalendar.com/href
https://www.austinprogressivecalendar.com/sites/default/files/styles/medium/public/inserted-images/content_landod8_2019-02-08_13-23-14.png?itok=yyuKDoPc
https://www.austinprogressivecalendar.com/index.php/href
...
```


Unfortunately this does not give you the URL of the page that contains the broken link.  You would have to manually search the site to find the broken link and fix it. I was able to output the log to a file with the `-o` option and then add a little bash script (thanks AI) that could find the broken links and the pages that contain them.



```sh
wget -e robots=off -r -nd --delete-after -l100 --spider -o wget.log https://austinprogressivecalendar.com./
```

The options used are:
- `-e robots=off`: Ignore robots.txt file
- `-r`: Recursive download
- `-nd`: No directories (save all files to current directory)
- `--delete-after`: Delete files after downloading (we only want to check links)
- `-l100`: Set the maximum recursion depth to 100
- `--spider`: Spider mode (check links only, do not download files)
- `-o wget.log`: Output log file
- `https://austinprogressivecalendar.com./`: The URL to crawl




::: tip Note
if you have basic HTTP authentication in place, you can add the options `--user=USERNAME` and `--ask-password` to the wget command to authenticate. For example:
```sh
wget --user=fredbloggs --ask-password -e robots=off -r -nd --delete-after -l100 --spider -o wget.log https://wzyzsite.prod.acquia-sites.com/
```
This will prompt you for the password when you run the command.
:::


Here is `find-broken-links.sh` that processes the wget log file to find broken links and the pages that contain them.

```bash
#!/bin/bash
# Usage: ./find-broken-links.sh `wget.log`

LOGFILE="$1"
if [ -z "$LOGFILE" ]; then
  echo "Usage: $0 logfile"
  exit 1
fi

awk '
# timestamp lines like --YYYY-MM-DD...
/^--[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ {
  urlstart = index($0, "https://")
  if (urlstart == 0) urlstart = index($0, "http://")
  if (urlstart > 0) {
    last = substr($0, urlstart)
    sp = index(last, " ")
    if (sp > 0) last = substr(last, 1, sp-1)
    gsub(/[[:punct:]]+$/, "", last)   # strip trailing punctuation
  }
  next
}

# When wget reports the remote file exists and could contain links,
# that last URL is the source page (contains outgoing links).
/Remote file exists and could contain links/ {
  if (last != "") source = last
  next
}

# 404 lines — report the broken URL (last) and the source page
/404 Not Found/ {
  broken = last
  # If the 404 line itself contains a URL, prefer that
  urlstart = index($0, "https://")
  if (urlstart == 0) urlstart = index($0, "http://")
  if (urlstart > 0) {
    broken = substr($0, urlstart)
    sp = index(broken, " ")
    if (sp > 0) broken = substr(broken, 1, sp-1)
    gsub(/[[:punct:]]+$/, "", broken)
  }
  print "Source: " (source != "" ? source : "(unknown)")
  print "Broken: " (broken != "" ? broken : "(no URL found)")
  print ""
  next
}
' "$LOGFILE"
```


And here is some sample output from the above bash script where 3 images are missing:

```
./find-broken-links.sh wget.log

Source: https://www.austinprogressivecalendar.com/node/92
Broken: https://www.austinprogressivecalendar.com/sites/default/files/styles/huge/public/inserted-images/content_landod8_2019-02-08_13-23-14.png?itok=h9R-_TbV

Source: https://www.austinprogressivecalendar.com/node/92
Broken: https://www.austinprogressivecalendar.com/sites/default/files/styles/medium/public/inserted-images/content_landod8_2019-02-08_13-23-14.png?itok=yyuKDoPc

Source: https://www.austinprogressivecalendar.com/node/92
Broken: https://www.austinprogressivecalendar.com/sites/default/files/styles/huge/public/inserted-images/incoming_connection_from_xdebug_2019-02-08_13-44-31.png?itok=1YPHA40R
```





In addition, you can use the [Link Checker](https://www.drupal.org/project/linkchecker) module to find (and continuously monitor) for broken links on your Drupal site.  Once installed and enabled, you can run the link checker from the admin interface. It does require quite a bit of configuration to get it working properly.


## How much space is being used by the files directory?

You can use the `du` command to find out how much space is being used by the `files` directory in Drupal.  The `-s` option provides a summary of the total size, the `-h` option makes the output human-readable, and the `--max-depth=1` option limits the output to just the top-level directories within `files`.

```sh
du -sh /var/www/html/docroot/sites/default/files/
```
Which might output something like:

```
6.8G	/var/www/html/docroot/sites/default/files/
```

Alternatively, if you want to see the size of each subdirectory within the `files` directory, you can use something like this:
```sh
du -h --max-depth=1 /path/to/drupal/sites/default/files
```

```sh
du -h --max-depth=1 /var/www/html/docroot/sites/default/files/
264K	/var/www/html/docroot/sites/default/files/dxpr_theme
14M	/var/www/html/docroot/sites/default/files/2023-04
3.7M	/var/www/html/docroot/sites/default/files/php
23M	/var/www/html/docroot/sites/default/files/cohesion
5.9M	/var/www/html/docroot/sites/default/files/config_dc6ba263b705940f2704111fcbc10188eba35b05
1012K	/var/www/html/docroot/sites/default/files/ad-blocks-2024-06
2.1M	/var/www/html/docroot/sites/default/files/ad-blocks-2025-05
1.2M	/var/www/html/docroot/sites/default/files/slider-image-2023-04
516K	/var/www/html/docroot/sites/default/files/ad-blocks-2023-07
164K	/var/www/html/docroot/sites/default/files/2024-03
668K	/var/www/html/docroot/sites/default/files/ad-blocks-2025-10
74M	/var/www/html/docroot/sites/default/files/styles
276K	/var/www/html/docroot/sites/default/files/ad-blocks-2024-11
204K	/var/www/html/docroot/sites/default/files/dxpr_theme_STARTERKIT
684K	/var/www/html/docroot/sites/default/files/element-preview-images
6.5G	/var/www/html/docroot/sites/default/files/documents
60K	/var/www/html/docroot/sites/default/files/translations
48K	/var/www/html/docroot/sites/default/files/paragraphs_type_icon
5.4M	/var/www/html/docroot/sites/default/files/inline-images
188K	/var/www/html/docroot/sites/default/files/ad-block-image-2023-04
284K	/var/www/html/docroot/sites/default/files/ad-blocks-2024-08
720K	/var/www/html/docroot/sites/default/files/ad-blocks-2025-07
20K	/var/www/html/docroot/sites/default/files/default_images
16K	/var/www/html/docroot/sites/default/files/config_io3Qgs5MEBCzUyv7dVBTVlfHQrGIOgd8_eOoK1RTTtKj3klT8w9GuUdUTn44kjRv-9i5njsrYw
1.5M	/var/www/html/docroot/sites/default/files/slider-image-2023-06
4.0K	/var/www/html/docroot/sites/default/files/2024-10
1.3M	/var/www/html/docroot/sites/default/files/ad-blocks-2025-12
2.8M	/var/www/html/docroot/sites/default/files/ad-blocks-2024-04
108M	/var/www/html/docroot/sites/default/files/images
7.7M	/var/www/html/docroot/sites/default/files/config_6d64f3d43412d4f3576014c677756d6974b7fe61
4.0K	/var/www/html/docroot/sites/default/files/library-definitions
552K	/var/www/html/docroot/sites/default/files/2024-09
36K	/var/www/html/docroot/sites/default/files/media-icons
2.1M	/var/www/html/docroot/sites/default/files/ad-blocks-2024-07
352K	/var/www/html/docroot/sites/default/files/ad-blocks-2025-06
1.1M	/var/www/html/docroot/sites/default/files/css
9.2M	/var/www/html/docroot/sites/default/files/2024-04
540K	/var/www/html/docroot/sites/default/files/ad-blocks-2025-02
160K	/var/www/html/docroot/sites/default/files/ad-blocks-2023-04
276K	/var/www/html/docroot/sites/default/files/ad-blocks-2024-12
2.3M	/var/www/html/docroot/sites/default/files/js
792K	/var/www/html/docroot/sites/default/files/ad-blocks-2024-10
12K	/var/www/html/docroot/sites/default/files/config_fYQtGPnbsA0RWMBMs0gwVorEkfCZdnv40GFcfwtv6dfDGLnBoF5lBkHnxVIfqBvSJmQc8VtESDR
4.3M	/var/www/html/docroot/sites/default/files/ad-blocks-2024-09
1008K	/var/www/html/docroot/sites/default/files/ad-blocks-2025-08
32M	/var/www/html/docroot/sites/default/files/private
4.1M	/var/www/html/docroot/sites/default/files/slider-image-2023-07
188K	/var/www/html/docroot/sites/default/files/2023-03
4.0K	/var/www/html/docroot/sites/default/files/2025-01
4.0K	/var/www/html/docroot/sites/default/files/2025-10
524K	/var/www/html/docroot/sites/default/files/ad-blocks-2023-06
16K	/var/www/html/docroot/sites/default/files/2024-02
1.3M	/var/www/html/docroot/sites/default/files/meeting-docs
124K	/var/www/html/docroot/sites/default/files/color
200K	/var/www/html/docroot/sites/default/files/pictures
6.8G	/var/www/html/docroot/sites/default/files/
```


## Key module

The [key module](https://www.drupal.org/project/key) provides a way to manage and use API keys in Drupal. It allows you to create and manage API keys for different services and applications allowing you to keep them out of your repo.

Key improves Drupal security by managing sensitive keys (such as API and encryption keys). You can define how and where keys are stored either config, file, state or environment variables. You can use the stream wrapper `private://` to store the file in the Drupal private file directory or just specify a full path on the server.

When configuring searchstax as a search provider, you can use the key module to store the endpoint and update_token. This can be stored as a `json` file e.g.

In your private files directory on your local ddev site: `sites/default/files/private/keys/searchstax_keys.json`

```json
{"update_endpoint":"https://searchcloud-4-us-west-2.searchstax.com/123456/sitearch-78910/update","update_token":"xxxxxxeaexxxxxxxxd737xxxxxx68efc0xxxxx9xxb"}
```

In the key module, you specify:
* key name (e.g. SearchStax connector credentials for migrated server)
* key type: Authentication
* Key provider: File
* File location: `private://keys/searchstax_keys.json`

To test if this is working, you can use drush to get the key value (after you have cleared the cache to ensure the key is loaded into the system):

```sh
ddev drush cr
ddev drush php-eval "echo \Drupal::service('key.repository')->getKey('searchstax_connector_migrated_searchstax_server')->getKeyValue();"
```
If this returns your json file contents, then you have successfully configured the key module to read from a file.

```json
{"update_endpoint":"https://searchcloud-4-us-west-2.searchstax.com/123456/sitearch-78910/update","update_token":"xxxxxxeaexxxxxxxxd737xxxxxx68efc0xxxxx9xxb"}
```

You can also use the dedicated drush command to get the key value:

```sh
drush key-value-get searchstax_connector_migrated_searchstax_server
```


:::tip Note
The Solr to SearchStax migration module (which is included with the [SearchStax module](https://www.drupal.org/project/searchstax) from Acquia) has built in support for the key module.  Unfortunately it will create keys that are stored in config rather than files. You need to copy the value from that key and store it in your file and update the file location to point to your json file.  The value is already in json form as shown above so you can just copy and paste it into your file.
:::

### Troubleshooting
To confirm that the file is legible use the following to list the file contents.  If you get an error, then the file is not readable or the path is incorrect.:

```sh
ddev exec cat /var/www/html/docroot/sites/default/files/private/keys/searchstax_server.json
{"update_endpoint":"https://searchcloud-4-us-west-2.searchstax.com/123456/sitearch-78910/update","update_token":"xxxxxxeaexxxxxxxxd737xxxxxx68efc0xxxxx9xxb"}
```



Use drush to get the key value to confirm that you are specifying the actual location you put the file in.

```sh
ddev drush config:get key.key.searchstax_connector_migrated_searchstax_server key_provider_settings
'key.key.searchstax_connector_migrated_searchstax_server:key_provider_settings':
  file_location: 'private://keys/searchstax_server.json'
  strip_line_breaks: false
```
If this returns the json value, this is wrong. You need to modify the key to use a file and specify the file location.


Look in `/admin/config/media/file-system` to see the private file system path.  This is where you need to put your json file.  If you have a different location for your private files, then you need to update the file location in the key configuration to point to the correct location.

### Overriding the value

In some instances, you will want to override the value of the key for a specific environment.  When using Acquia hosting, the private file system will get overwritten when you copy the files from the prod environment to the dev environment.  This means your `/env/searchstax_server.json` file will get replaced. This is dangerous as the value from prod will be accidentally used and you may corrupt the production searchstax index.

In this case, you can use the `settings.php` (or `settings.acquia.php`) file to override the value of the key for the dev environment.  You can do this by adding the following code to your `settings.php` file:

```php
// Which environment are we on? Default to 'local' if not set.
$env = $_ENV['AH_SITE_ENVIRONMENT'] ?? 'local';
/*
 * Overwrite key value with environment specific path
 * like /mnt/gfs/weccwebsite.dev/nobackup.
 */
$searchstax_server_json_location = '/mnt/gfs/weccwebsite' . '.' . $env . '/nobackup/searchstax_server.json';
$config['key.key.searchstax_connector_migrated_searchstax_server']['key_provider_settings']['file_location'] = $searchstax_server_json_location;
```

To test the override, use drush to see the file location (getKeyProvider()->getConfiguration()):
```sh
$ drush php-eval "print_r(\Drupal::service('key.repository')->getKey('searchstax_connector_migrated_searchstax_server')->getKeyProvider()->getConfiguration());"
Array
(
    [file_location] => /mnt/gfs/weccwebsite.dev/nobackup/searchstax_server.json
    [strip_line_breaks] =>
)
```

and the values (getKeyValues()):

```sh
$ drush php-eval "print_r(\Drupal::service('key.repository')->getKey('searchstax_connector_migrated_searchstax_server')->getKeyValues());"
Array
(
    [0] => {"update_endpoint":"https://searchcloud-2-us-west-2.searchstax.com/12345/westernelectricitycoordi-6789/update","update_token":"xxxxxxeaexxxxxxxxd737xxxxxx68efc0xxxxx9xxb"}
)
```



This will return the value from config storage and ignore any runtime overrides i.e. What the value is before the override is applied.:

```sh
$ drush config:get key.key.searchstax_connector_migrated_searchstax_server key_provider_settings
'key.key.searchstax_connector_migrated_searchstax_server:key_provider_settings':
  file_location: 'private://keys/searchstax_server.json'
  strip_line_breaks: false
```






---

**Last synced**: 2026-08-08
