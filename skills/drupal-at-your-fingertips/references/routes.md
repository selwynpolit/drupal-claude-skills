# Routes & Controllers

**Source**: [Drupal at Your Fingertips - routes](https://drupalatyourfingertips.com/routes)
**Author**: Selwyn Polit

Quick reference for Drupal routing and controllers with practical code examples.

---

## Core Concept

Routes map URLs to controller methods. Defined in `my_module.routing.yml`, they specify path, controller, title, and access requirements.

## Basic Route Definition

**In my_module.routing.yml**:
```yaml
my_module.hello:
  path: '/hello'
  defaults:
    _controller: '\Drupal\my_module\Controller\HelloController::hello'
    _title: 'Hello Page'
  requirements:
    _permission: 'access content'
```

**Controller** (src/Controller/HelloController.php):
```php
namespace Drupal\my_module\Controller;

use Drupal\Core\Controller\ControllerBase;

class HelloController extends ControllerBase {

  public function hello() {
    return [
      '#markup' => $this->t('Hello World!'),
    ];
  }
}
```

---

## Route Parameters

**Dynamic URL segments**:
```yaml
my_module.user_page:
  path: '/user/{user}/profile'
  defaults:
    _controller: '\Drupal\my_module\Controller\UserController::viewProfile'
    _title: 'User Profile'
  requirements:
    _permission: 'access user profiles'
    user: \d+  # Numeric only
```

**Controller receives parameters**:
```php
public function viewProfile($user) {
  $user_entity = User::load($user);

  if (!$user_entity) {
    throw new \Symfony\Component\HttpKernel\Exception\NotFoundHttpException();
  }

  return [
    '#markup' => $this->t('Profile for @name', [
      '@name' => $user_entity->getDisplayName(),
    ]),
  ];
}
```

**Auto-upcasting** (load entity from parameter):
```yaml
my_module.node_custom:
  path: '/node/{node}/custom'
  defaults:
    _controller: '\Drupal\my_module\Controller\NodeController::customView'
  requirements:
    _permission: 'access content'
  options:
    parameters:
      node:
        type: entity:node
```

```php
use Drupal\node\NodeInterface;

public function customView(NodeInterface $node) {
  // $node is automatically loaded
  return [
    '#markup' => $this->t('Node title: @title', [
      '@title' => $node->getTitle(),
    ]),
  ];
}
```

---

## Access Control

**Permission-based**:
```yaml
requirements:
  _permission: 'administer site configuration'
```

**Multiple permissions** (OR logic with +):
```yaml
requirements:
  _permission: 'edit own content+administer content'
```

**Role-based**:
```yaml
requirements:
  _role: 'administrator+editor'
```

**Custom access check**:
```yaml
requirements:
  _custom_access: '\Drupal\my_module\Controller\MyController::checkAccess'
```

```php
public function checkAccess() {
  $user = \Drupal::currentUser();
  return AccessResult::allowedIf($user->id() > 1);
}
```

---

## Dynamic Page Titles

**Title callback**:
```yaml
my_module.dynamic_title:
  path: '/content/{node}'
  defaults:
    _controller: '\Drupal\my_module\Controller\ContentController::view'
    _title_callback: '\Drupal\my_module\Controller\ContentController::getTitle'
```

```php
public function getTitle(NodeInterface $node) {
  return $this->t('@title Details', ['@title' => $node->getTitle()]);
}
```

---

## Returning Different Response Types

**Render array** (most common):
```php
public function buildPage() {
  return [
    '#theme' => 'my_template',
    '#data' => $this->getData(),
  ];
}
```

**JSON response**:
```php
use Symfony\Component\HttpFoundation\JsonResponse;

public function apiEndpoint() {
  $data = [
    'status' => 'success',
    'items' => $this->getItems(),
  ];

  return new JsonResponse($data, 200, [
    'Cache-Control' => 'no-cache, must-revalidate',
  ]);
}
```

**Redirect**:
```php
use Symfony\Component\HttpFoundation\RedirectResponse;
use Drupal\Core\Url;

public function redirectExample() {
  $url = Url::fromRoute('my_module.other_page');
  return new RedirectResponse($url->toString());
}
```

**File download**:
```php
use Symfony\Component\HttpFoundation\BinaryFileResponse;

public function downloadFile() {
  $file_path = '/path/to/file.pdf';
  return new BinaryFileResponse($file_path);
}
```

---

## ControllerBase Shortcuts

**No DI required for these**:
```php
class MyController extends ControllerBase {

  public function buildPage() {
    // Entity storage
    $storage = $this->entityTypeManager()->getStorage('node');

    // Current user
    $user = $this->currentUser();

    // Configuration
    $config = $this->config('system.site');

    // Messenger
    $this->messenger()->addStatus($this->t('Message'));

    // Module handler
    $this->moduleHandler()->moduleExists('views');

    // Form builder
    $form = $this->formBuilder()->getForm('Drupal\my_module\Form\MyForm');

    return $form;
  }
}
```

---

## Route Options

**Disable caching**:
```yaml
options:
  no_cache: TRUE
```

**Admin route** (uses admin theme):
```yaml
options:
  _admin_route: TRUE
```

**Parameter constraints**:
```yaml
options:
  parameters:
    node:
      type: entity:node
    user:
      type: entity:user
```

---

## Common Route Patterns

| Pattern | Example | Use Case |
|---------|---------|----------|
| Simple page | `/about` | Static content |
| Entity view | `/node/{node}` | Entity display |
| Entity edit | `/node/{node}/edit` | Entity forms |
| User-specific | `/user/{user}/messages` | User-related pages |
| Admin config | `/admin/config/my-module` | Settings forms |
| API endpoint | `/api/v1/content` | JSON responses |

---

---

## Debugging Routes

**List all routes**:
```bash
drush route
```

**Find route by path**:
```bash
drush route --path=/admin/config
```

**Find route by name**:
```bash
drush route --name=my_module.hello
```

**Generate controller**:
```bash
drush generate controller
```

---

## More Snippets (from the General chapter)

_Merged from the d9book "general" chapter, which was too large to keep as a single reference file._

### Get the current user

Note, this will not get the user entity, but rather a user proxy with basic info but no fields or entity-specific data.

```php
$user = \Drupal::currentUser();
```

```php
$user = \Drupal\user\Entity\User::load(\Drupal::currentUser()->id());
```

Or

```php
use \Drupal\user\Entity\User;
$user = User::load(\Drupal::currentUser()->id());
```

### Get the logged-in user name and email

```php
$username = \Drupal::currentUser()->getAccountName();
```

or

```php
$account_proxy = \Drupal::currentUser();
//$account = $account_proxy->getAccount();

// load user entity
$user = User::load($account_proxy->id());

$user = User::load(\Drupal::currentUser()->id());
$name = $user->get('name')->value;
```

Email

```php
$email = \Drupal::currentUser()->getEmail();
```

or

```php
$user = User::load(\Drupal::currentUser()->id());
$email = $user->get('mail')->value;
```

### Get the current Path

`\Drupal::service('path.current')->getPath()` returns the current relative path. For node pages, the return value will be in the form "/node/32" For taxonomy "taxonomy/term/5", for user "user/2" if it exists, otherwise it will return the current request URI.

```php
$current_path  = \Drupal::service('path.current')->getPath();
// Get the alias (i.e. if the user entered node/123, this will return e.g. /bicycles/super-cool-one)
$alias = \Drupal::service('path_alias.manager')->getAliasByPath($current_path);

// Get path with query string e.g. /abc/def/123?a=fred.
$current_path_and_alias = \Drupal::request()->getRequestUri();

// Get path e.g. /abc/def/123
$current_path = Url::fromRoute('<current>')->toString();
```

[Lots more on the Drupal Stackexchange](https://drupal.stackexchange.com/questions/106103/how-do-i-get-the-current-path-alias-or-path)

### Check if you are on the Front page

```php
$is_front = \Drupal::service('path.matcher')->isFrontPage();
```

The above statement will return either TRUE or FALSE. TRUE means you are on the front page.

### Retrieve the Symfony Request object

```php
$request = \Drupal::request();
```

### Retrieve query, get or post parameters

For `get` variables use:
```php
$query = \Drupal::request()->query->get('name');
```

For `post` variables use:

```php
$name = \Drupal::request()->request->get('name');
```

For all items in a `get`:

```php
$query = \Drupal::request()->query->all();
$search_term = $query['query'];
$collection = $query['collection'];
```

::: tip Note
Drupal will cache requests so render arrays need cache contexts specified correctly in order to successfully retrieve those parameters. See the caching reference for setting cache context correctly when retrieving query, get or post parameters.
:::

### Retrieve the query string

```php
$request->getQueryString()
```
e.g. if a url has `?_wrapper_format=drupal_ajax&ajax_form=1` this will return `_wrapper_format=drupal_ajax&ajax_form=1`

### Get Node URL alias or Taxonomy Alias by Node id or Term ID

Sometimes we need a relative path and sometimes we need an absolute path. There is an `$options` parameter in the `fromRoute()` function where you specify which you need.

Parameters:

- absolute true will return absolute path.
- absolute false will return relative path.

Returns the node alias. Note, if a nice URL is not set using pathauto, you get `/node/1234`

```php
use Drupal\Core\Url;
$options = ['absolute' => true];  //false will return relative path.

$url = Url::fromRoute('entity.node.canonical', ['node' => 1234], $options);
$url = $url->toString(); // make a string

// OR

$node_path = "/node/1";
$alias = \Drupal::service('path_alias.manager')->getAliasByPath($node_path);

// OR

$current_path = \Drupal::service('path.current')->getPath();
```

To get the full path with the host etc. this returns something like: https://example.ddev.site/node/1

```php
$host = \Drupal::request()->getSchemeAndHttpHost();
$url = \Drupal\Core\Url::fromRoute('entity.node.canonical',['node'=>$lab_home_nid]);
$url_alias = $url->toString();
$full_url = $host . $url->toString();
```

You can get the hostname directly from the `getHost()` request with:

```php
$host = \Drupal::request()->getHost();
```

### Taxonomy alias

Return taxonomy alias:

```php
$options = ['absolute' => true];  //false will return relative path.
$url = Url::fromRoute('entity.taxonomy_term.canonical', ['taxonomy_term' => 1234], $options);
```

### Get current nid, node type and title

There are two ways to retrieve the current node -- via the request or the route:

```php
$node = \Drupal::request()->attributes->get('node');
$nid = $node->id();
```

OR

```php
$node = \Drupal::routeMatch()->getParameter('node');
if ($node instanceof \Drupal\node\NodeInterface) {
  // You can get nid and anything else you need from the node object.
  $nid = $node->id();
  $nodeType = $node->bundle();
  $nodeTitle = $node->getTitle();
}
```

If you need to use the node object in `hook_preprocess_page` on the preview page, you will need to use the `node_preview` parameter, instead of the `node` parameter:

```php
function mymodule_preprocess_page(&$vars) {
  $route_name = \Drupal::routeMatch()->getRouteName();

  if ($route_name == 'entity.node.canonical') {
    $node = \Drupal::routeMatch()->getParameter('node');
  }
  elseif ($route_name == 'entity.node.preview') {
    $node = \Drupal::routeMatch()->getParameter('node_preview');
  }
}
```

When using or creating a custom block, follow this pattern to get the current node id and set up correct caching:

```php
use Drupal\Core\Cache\Cache;

$node = \Drupal::routeMatch()->getParameter('node');
if ($node instanceof \Drupal\node\NodeInterface) {
  $nid = $node->id();
}

// for cache
public function getCacheTags() {
  // With this when your node changes your block will rebuild.
  if ($node = \Drupal::routeMatch()->getParameter('node')) {
    // If there is a node, add its cache tag.
    return Cache::mergeTags(parent::getCacheTags(), ['node:' . $node->id()]);
  }
  else {
    // Return default tags instead.
    return parent::getCacheTags();
  }
}

public function getCacheContexts() {
  // If you depend on \Drupal::routeMatch() you must set the context of
  // this block with the 'route' context tag. Every new route this block
  // will rebuild.
  return Cache::mergeContexts(parent::getCacheContexts(), ['route']);
}
```

### Get current Route name

Routes are in the form: `view.files_browser.page_1`, `test.example` or `test.settings_form`.

```php
$current_route = \Drupal::routeMatch()->getRouteName();
```

This returns `entity.node.canonical` for nodes, `system.404` for 404 pages, `entity.taxonomy_term.canonical` for taxonomy pages, `entity.user.canonical` for users, and the custom route name defined in `modulename.routing.yml`.

### Get the current page title

Use this in a controller to return the current page title:

```php
$request = \Drupal::request();
if ($route = $request->attributes->get(\Symfony\Cmf\Component\Routing\RouteObjectInterface::ROUTE_OBJECT)) {
  $title = \Drupal::service('title_resolver')->getTitle($request, $route);
}
```

### Retrieve URL argument parameters

Extract URL arguments with:

```php
$current_path = \Drupal::service('path.current')->getPath();
$path_args = explode('/', $current_path);
$term_name = $path_args[3];
```

### Get Current Language in a constructor

Using dependency injection, inject `LanguageManagerInterface` and call `getCurrentLanguage()`:

```php
class WEAResource extends ResourceBase {

  /**
   * @var \Drupal\Core\Language\Language
   */
  protected $currentLanguage;

  public function __construct(array $configuration, string $plugin_id, mixed $plugin_definition, array $serializer_formats, \Psr\Log\LoggerInterface $logger, LanguageManagerInterface $language_manager) {
    parent::__construct($configuration, $plugin_id, $plugin_definition, $serializer_formats, $logger);
    $this->currentLanguage = $language_manager->getCurrentLanguage();
  }
}
```

Later in the class, retrieve the correct language version of the node:

```php
public function get($id) {
  if ($node = Node::load($id)) {
    $translatedNode = $node->getTranslation($this->currentLanguage->getId());
  }
}
```

You can also get the language statically:

```php
$language = \Drupal::languageManager()->getLanguage(LanguageInterface::TYPE_INTERFACE);
```

### Decoding URL encoded strings

Encoded strings have all non-alphanumeric characters except `-_.` replaced with a percent (%) sign followed by two hex digits, and spaces encoded as plus (+) signs — the same encoding as posted form data (`application/x-www-form-urlencoded`).

```php
echo urldecode("threatgeek/2016/05/welcome-jungle-tips-staying-secure-when-you%E2%80%99re-road") . "\n";
echo urldecode('We%27re%20proud%20to%20introduce%20the%20Amazing') . "\n";
```

returns:

```
threatgeek/2016/05/welcome-jungle-tips-staying-secure-when-you're-road
We're proud to introduce the Amazing
```

Encoding looks like this:

```php
echo urlencode("threatgeek/2016/05/welcome-jungle-tips-staying-secure-when-you're-road") . "\n";
```

returns:

```
threatgeek%2F2016%2F05%2Fwelcome-jungle-tips-staying-secure-when-you%E2%80%99re-road
```

---

## Key Guidelines

✅ **Use meaningful route names** - `my_module.action_description`
✅ **Validate parameters** - Check input before using
✅ **Use auto-upcasting** - Let Drupal load entities
✅ **Return correct response types** - Render array for pages, JsonResponse for APIs
✅ **Set appropriate access** - Always require permissions
✅ **Use title callbacks** - For dynamic titles
✅ **Follow URL patterns** - Use hyphens, not underscores

❌ **Don't use internal IDs in public URLs** - Use UUIDs for APIs
❌ **Don't skip access checks** - Always set requirements
❌ **Don't hardcode redirects** - Use `Url::fromRoute()`
❌ **Don't forget 404 responses** - Throw NotFoundHttpException
❌ **Don't use `_controller` for forms** - Use `_form` instead

---

**Full documentation**: https://drupalatyourfingertips.com/routes
