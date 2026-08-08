# Twig Templates

**Source**: [Drupal at Your Fingertips - twig](https://drupalatyourfingertips.com/twig)
**Author**: Selwyn Polit

Quick reference for Twig templating in Drupal with practical code examples.

---

## Core Concept

Twig is Drupal's template engine for rendering HTML. Templates use `.html.twig` extension and follow a suggestion hierarchy. Use `content.field_name` for rendered output (with labels/formatting) and `node.field_name.value` for raw values.

## Twig Syntax

**Three syntaxes**:
```twig
{# This is a comment #}

{{ variable }}  {# Output variable (auto-escaped) #}

{% if condition %}  {# Logic statement #}
  ...
{% endif %}
```

---

## Template Naming & Suggestions

**Naming pattern** - Most specific to least:
```twig
{# Node templates #}
node--article--123.html.twig       {# Specific node ID #}
node--article--full.html.twig      {# Content type + view mode #}
node--article.html.twig            {# Content type #}
node--full.html.twig               {# View mode #}
node.html.twig                     {# Base template #}

{# Field templates #}
field--field-tags--article.html.twig  {# Field + content type #}
field--field-tags.html.twig           {# Field name #}
field--entity-reference.html.twig     {# Field type #}
field.html.twig                       {# Base template #}

{# Views templates #}
views-view--my-view--page.html.twig   {# View + display #}
views-view--my-view.html.twig         {# View name #}
views-view.html.twig                  {# Base template #}
```

**Enable debug mode** to see suggestions in HTML comments.

---

## Variable Access Patterns

**Two ways to access fields**:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `content.` | Rendered output with wrappers | `{{ content.field_image }}` |
| `node.` | Raw field values | `{{ node.field_image.0.target_id }}` |

**Content prefix** (rendered with labels/formatting):
```twig
{{ content.field_image }}
{{ content.field_title }}
{{ content.body }}
```

**Node prefix** (raw values):
```twig
{{ node.title.value }}
{{ node.field_tags.0.target_id }}
{{ node.field_date.value|date('Y-m-d') }}
```

---

## Common Field Types

**Text fields**:
```twig
{{ content.field_description }}
{{ node.field_description.value }}
{{ node.field_description.0.value }}
```

**Entity reference fields**:
```twig
{# Get referenced entity ID #}
{{ node.field_author.0.target_id }}

{# Get referenced entity label #}
{{ node.field_author.entity.label }}

{# Get referenced entity field #}
{{ node.field_author.entity.field_bio.value }}
```

**Boolean fields**:
```twig
{% if content.field_featured['#items'].0.value %}
  <span class="featured">Featured</span>
{% endif %}
```

**Date fields**:
```twig
{# Rendered date #}
{{ content.field_publish_date }}

{# Format raw date #}
{{ node.field_publish_date.value|date('F j, Y') }}
{{ node.field_publish_date.0.value|date('Y-m-d') }}

{# Node created/changed #}
{{ node.created.value|date('Y-m-d') }}
{{ node.changed.value|date('Y-m-d') }}
```

**Link fields**:
```twig
{# Rendered link #}
{{ content.field_website }}

{# Link parts #}
<a href="{{ node.field_website.0.url }}">
  {{ node.field_website.0.title }}
</a>
```

**File fields**:
```twig
{# Rendered file #}
{{ content.field_document }}

{# File URL and name #}
{% for file in node.field_document %}
  <a href="{{ file.entity.uri.value|file_url }}">
    {{ file.entity.filename.value }}
  </a>
{% endfor %}
```

**Image fields**:
```twig
{# Rendered image #}
{{ content.field_image }}

{# Image URL #}
{{ node.field_image.entity.uri.value|file_url }}

{# Alt text #}
{{ node.field_image.alt }}
```

---

## Twig Filters

**Essential Drupal filters**:
| Filter | Purpose | Example |
|--------|---------|---------|
| `\|t` | Translate | `{{ 'Hello'|t }}` |
| `\|raw` | Output unescaped HTML | `{{ content.body\|raw }}` |
| `\|striptags` | Remove HTML tags | `{{ content.body\|striptags }}` |
| `\|render` | Render arrays | `{{ content.field_x\|render }}` |
| `\|without('field')` | Exclude fields | `{{ content\|without('field_x') }}` |
| `\|file_url` | File URI to URL | `{{ uri\|file_url }}` |
| `\|date('format')` | Format dates | `{{ date\|date('Y-m-d') }}` |
| `\|clean_class` | HTML class names | `{{ label\|clean_class }}` |
| `\|join('+')` | Join array | `{{ ids\|join('+') }}` |
| `\|length` | Array/string length | `{{ items\|length }}` |
| `\|upper`, `\|lower` | Case transform | `{{ title\|upper }}` |

**Common patterns**:
```twig
{# Check if field has content #}
{% if content.body|render|striptags|trim is not empty %}
  {{ content.body }}
{% endif %}

{# Remove specific tags #}
{{ content.field_text|striptags('<b>,<a>')|raw }}

{# Format class name #}
<div class="{{ node.bundle|clean_class }}">
```

---

## Twig Functions

**Drupal functions**:
```twig
{# Generate URLs #}
<a href="{{ url('entity.node.canonical', {node: 123}) }}">Node Link</a>
<a href="{{ path('entity.node.canonical', {node: 123}) }}">Relative Path</a>

{# Render views #}
{{ drupal_view('my_view', 'block_1') }}
{{ drupal_view('my_view', 'block_1', arg1, arg2) }}

{# Check view has results #}
{% if drupal_view_result('my_view', 'block_1')|length %}
  {{ drupal_view('my_view', 'block_1') }}
{% endif %}

{# Render blocks #}
{{ drupal_block('system_branding_block') }}
{{ drupal_block('views_block:my_view-block_1') }}

{# Render specific field #}
{{ drupal_field('field_tags', 'node') }}

{# Debug output #}
{{ dump(variable) }}
{{ kint(variable) }}
```

---

## Control Structures

**Conditionals**:
```twig
{% if content.field_featured %}
  <div class="featured">{{ content.field_featured }}</div>
{% elseif content.field_promoted %}
  <div class="promoted">{{ content.field_promoted }}</div>
{% else %}
  <div class="regular">Regular content</div>
{% endif %}
```

**Loops**:
```twig
{% for item in items %}
  {{ item }}

  {% if loop.first %}First{% endif %}
  {% if loop.last %}Last{% endif %}
  {{ loop.index }}  {# 1-indexed #}
  {{ loop.index0 }} {# 0-indexed #}
{% endfor %}

{# Loop with separator #}
{% for tag in node.field_tags %}
  {% if not loop.first %}, {% endif %}
  {{ tag.entity.label }}
{% endfor %}
```

**Setting variables**:
```twig
{% set classes = ['node', node.bundle, 'view-mode-' ~ view_mode] %}
<div{{ attributes.addClass(classes) }}>

{% set name = 'Hello !name'|t({'!name': user.name}) %}
```

---

## Attributes & Classes

**Add classes**:
```twig
{% set classes = ['article', 'featured'] %}
<div{{ attributes.addClass(classes) }}>

{# Conditional classes #}
{% set classes = [
  'node',
  node.bundle|clean_class,
  node.isPromoted() ? 'promoted',
  'view-mode-' ~ view_mode|clean_class,
] %}
<div{{ attributes.addClass(classes) }}>
```

**Attribute operations**:
```twig
{{ attributes.setAttribute('data-id', node.id) }}
{{ attributes.removeClass('unwanted-class') }}
{{ attributes.removeAttribute('id') }}

{% if attributes.hasClass('check-this') %}
  ...
{% endif %}
```

---

## Including Templates

**Include partial templates**:
```twig
{# Include from theme #}
{% include '@mytheme/partials/header.html.twig' %}

{# Include with variables #}
{% include '@mytheme/partials/card.html.twig' with {
  'title': node.title.value,
  'image': node.field_image
} %}

{# Include only these variables #}
{% include '@mytheme/partials/item.html.twig' with {
  'item': item
} only %}
```

---

## Preprocessing

**Add variables in .theme file**:
```php
function mytheme_preprocess_node(&$variables) {
  $node = $variables['node'];

  // Add custom variable
  $variables['author_name'] = $node->getOwner()->getDisplayName();

  // Add formatted date
  $variables['formatted_date'] = \Drupal::service('date.formatter')
    ->format($node->getCreatedTime(), 'custom', 'F j, Y');
}
```

**Use in template**:
```twig
<div class="author">{{ author_name }}</div>
<div class="date">{{ formatted_date }}</div>
```

---

## Debugging

**Enable debug mode** (sites/development.services.yml):
```yaml
parameters:
  twig.config:
    debug: true
    auto_reload: true
    cache: false
```

**Debug functions**:
```twig
{# Basic dump #}
{{ dump(variable) }}

{# Dump specific properties #}
{{ dump(node.title) }}
{{ dump(node.field_tags.0) }}

{# Kint (requires Devel module) #}
{{ kint(node) }}
```

**View template suggestions** (in HTML source):
```html
<!-- FILE NAME SUGGESTIONS:
   * node--article--123.html.twig
   * node--article--full.html.twig
   x node--article.html.twig
   * node--full.html.twig
   * node.html.twig
-->
```

---

## Regions

**Define in mytheme.info.yml**:
```yaml
regions:
  header: Header
  primary_menu: 'Primary Menu'
  content: Content
  sidebar_first: 'Left Sidebar'
  footer: Footer
```

**Use in templates**:
```twig
{% if page.header %}
  <header>{{ page.header }}</header>
{% endif %}

{% if page.sidebar_first %}
  <aside class="sidebar">{{ page.sidebar_first }}</aside>
{% endif %}
```

---

---

## More Preprocess Snippets (from the General chapter)

_Merged from the d9book "general" chapter, which was too large to keep as a single reference file._

### Add a variable to any page on the site

In the theme's `.theme` file, add a `hook_preprocess_page` function:

```php
function mytheme_preprocess_page(&$variables) {
  $variables['footer_address1'] = [
    '#type' => 'markup',
    '#markup' => '123 Disk Drive, Sector 439',
  ];
  $variables['footer_address2'] = [
    '#type' => 'markup',
    '#markup' => 'Austin, Texas 78759',
  ];
}
```

Then in the template file, e.g. `templates/partials/footer.html.twig`:

```twig
<div class="cell xlarge-3 medium-4">
  <address>
    {{ footer_address1 }}<br />
    {{ footer_address2 }}<br />
  </address>
</div>
```

### Add a variable to be rendered in a node

Add vars in `hook_preprocess_node` in the theme's `.theme` file — here `stock_field` and `my_custom_field` are added and rendered by a normal node Twig file:

```php
function mytheme_preprocess_node(&$variables) {
  $variables['content']['stock_field'] = [
    '#type' => 'markup',
    '#markup' => 'stock field here',
  ];

  $variables['content']['my_custom_field'] = [
    '#type' => 'markup',
    '#markup' => 'Hello - custom field here',
  ];
}
```

If you've tweaked your node Twig template, reference it like this:

```twig
<div class="stock-field-class">
  {{ content['stock_field'] }}
</div>
```

You can also add a variable directly and reference it in the template:

```php
$variables['abc'] = 'hello';
```

```twig
{{ abc }}
{# or, for debugging: #}
{{ kint(abc) }}
```

### Add a bunch of variables to be rendered in a node

Grab the node from `$variables`, then cycle through multi-value reference fields to build an array Twig can render easily:

```php
function mytheme_preprocess_node(&$variables) {
  $view_mode = $variables['view_mode'];
  $allowed_view_modes = ['full']; // Restrict for performance.
  $node = $variables['node'];
  if (($node->getType() == 'news_story') && ($view_mode == 'full')) {
    $aofs = _mytheme_multival_ref_data($node->field_ref_aof, 'aof', 'target_id');
    $topics = _mytheme_multival_ref_data($node->field_ref_topic, 'topic', 'target_id', 'taxonomy');
    $related_news_items = array_merge($topics, $aofs);
    $variables['related_news_items'] = $related_news_items;
  }
}

/**
 * Returns array of data for multivalue node reference fields.
 */
function _mytheme_multival_ref_data($ref_field, $param_name, $value_type, $field_ref_type = 'node') {
  $values = [];
  foreach ($ref_field as $ref) {
    if ($field_ref_type == 'taxonomy') {
      $term = \Drupal::entityTypeManager()->getStorage('taxonomy_term')->load($ref->$value_type);
      $title = $term->getName();
    }
    else {
      $title = $value_type == 'value' ? $ref->$value_type : $ref->entity->title->value;
    }
    $values[] = [
      'title' => $title,
      'id' => str_replace(' ', '+', $ref->$value_type),
      'param_name' => $param_name,
    ];
  }
  return $values;
}
```

### Grabbing entity reference fields in hook_preprocess_node for injection into the twig template

Pull in referenced fields directly:

```php
$node->field_sf_contract_ref->entity->field_how_to_order->value;
```

Where `field_sf_contract_ref` is the reference field pointing to an entity with a `field_how_to_order` field. Assign it into `$variables` and use it in the template as `{{ how_to_order }}`:

```php
function mytheme_preprocess_node(&$variables) {
  $node = $variables['node'];
  $type = $node->bundle();
  if ($type === 'contract') {
    if ($variables['view_mode'] === 'full') {
      $how_to_order_lookup = $node->field_sf_contract_ref->entity->field_how_to_order_lookup->value;
      $variables['how_to_order_lookup'] = $how_to_order_lookup;
      $contract_type = $node->get('field_contract_type')->value;
      if ($how_to_order_lookup === 'Custom Text') {
        $variables['how_to_order'] = $contract_type === 'DIRT'
          ? $node->field_sf_contract_ref->entity->field_how_to_order->value
          : $node->field_sf_contract_ref->entity->field_how_to_order_custom->value;
      }
    }
  }
}
```

### Render a list created in the template_preprocess_node()

Build a list in `hook_preprocess_node`:

```php
function mytheme_preprocess_node(&$variables) {
  $variables['burgers'] = [
    ['name' => 'Cheeseburger'],
    ['name' => 'Mushroom Swissburger'],
    ['name' => 'Jalapeno burger'],
  ];
}
```

Render it in the Twig template, e.g. `node--article--full.html.twig`:

```twig
<ol>
  {% for burger in burgers %}
    <li> {{ burger['name'] }} </li>
  {% endfor %}
</ol>
```

### Indexing paragraphs so you can theme the first one

Add an index to paragraph items referenced as `{{ paragraph.index }}` in the Twig template:

```php
/**
 * Implements hook_preprocess_field().
 *
 * Provides an index for these fields referenced as {{ paragraph.index }}
 * in twig template.
 */
function mytheme_preprocess_field(&$variables) {
  if ($variables['field_name'] == 'field_video_accordions') {
    foreach ($variables['items'] as $idx => $item) {
      $variables['items'][$idx]['content']['#paragraph']->index = $idx;
    }
  }
}
```

`field_video_accordions` is the name of the field holding the paragraphs to count. In the paragraph's Twig template:

```twig
{% if paragraph.index == 0 %}
  <li class="accordion-item is-active" data-accordion-item="">
{% else %}
  <li class="accordion-item" data-accordion-item="">
{% endif %}
```

### Add meta tags using template_preprocess_html

Modify `<head>` in `hook_preprocess_html`. Build a fake array of meta tags and attach them via `$variables['page']['#attached']['html_head']`:

```php
/**
 * Implements hook_preprocess_html().
 */
function mytheme_preprocess_html(&$variables) {
  $node = \Drupal::routeMatch()->getParameter('node');
  if ($node instanceof \Drupal\node\NodeInterface && $node->getType() == 'contract') {
    $brand_meta_tag = [
      [
        '#tag' => 'meta',
        '#attributes' => [
          'name' => 'brand',
          'content' => 'Dell',
        ],
      ],
      'Dell',
    ];
    $variables['page']['#attached']['html_head'][] = $brand_meta_tag;
  }
}
```

The second array element (`'Dell'`) is a description key, not rendered directly — if you don't need it, use:

```php
$page['#attached']['html_head'][] = [$description, 'description'];
```

For multiple tags, loop and append each:

```php
$brand_meta_tags = [];
$brand_meta_tags[] = [['#tag' => 'meta', '#attributes' => ['name' => 'brand', 'content' => 'Dell']], 'Dell'];
$brand_meta_tags[] = [['#tag' => 'meta', '#attributes' => ['name' => 'brand', 'content' => 'Apple']], 'Apple'];

foreach ($brand_meta_tags as $brand_meta_tag) {
  $variables['page']['#attached']['html_head'][] = $brand_meta_tag;
}
```

Building tags from a query:

```php
$brand_meta_tags = [];
$contract_id = $node->field_contract_id->value;
if ($contract_id) {
  $query = \Drupal::entityQuery('node')
    ->condition('type', 'sf_store_brands')
    ->condition('status', 1)
    ->condition('field_contract_id', $contract_id);
  $nids = $query->execute();
  foreach ($nids as $nid) {
    $store_brand_node = Node::load($nid);
    $brand = $store_brand_node->field_brand->value;
    if ($brand) {
      $brand_meta_tags[] = [
        ['#tag' => 'meta', '#attributes' => ['name' => 'brand', 'content' => $brand]],
        $brand,
      ];
    }
  }
  foreach ($brand_meta_tags as $brand_meta_tag) {
    $variables['page']['#attached']['html_head'][] = $brand_meta_tag;
  }
}
```

### Add StringTranslationTrait to a class to use $this->t()

To use `$this->t()` in a class, add `use StringTranslationTrait`:

```php
namespace Drupal\my_module;

use Drupal\Core\StringTranslation\StringTranslationTrait;

final class MenuTableBuilder implements MenuTableBuilderInterface {

  use StringTranslationTrait;

  public function buildTable(int $page): array {
    $rows = [];
    foreach ($pagedMenus as $menu_name => $menu) {
      $edit_url = Url::fromRoute('entity.menu.edit_form', ['menu' => $menu_name]);
      $rows[] = [
        'title' => $menu->label(),
        'operations' => [
          'data' => [
            '#type' => 'operations',
            '#links' => [
              'edit' => [
                'title' => $this->t('Edit'),
                'url' => $edit_url,
              ],
            ],
          ],
        ],
      ];
    }
    return $rows;
  }

}
```

---

## Key Guidelines

✅ **Use template suggestions** - Most specific first
✅ **Use content. for rendered output** - Includes labels/wrappers
✅ **Use node. for raw values** - Direct field access
✅ **Use filters for safety** - |t, |striptags, |clean_class
✅ **Enable debug mode** - During development
✅ **Use preprocessing** - For complex logic
✅ **Check field existence** - Use {% if content.field_name %}
✅ **Use Twig Tweak module** - For drupal_view, drupal_block

❌ **Don't use PHP in templates** - Preprocess instead
❌ **Don't forget |t filter** - For translatable strings
❌ **Don't use |raw carelessly** - Security risk
❌ **Don't access nodes directly** - Use provided variables
❌ **Don't cache templates in dev** - Enable auto_reload
❌ **Don't forget to clear cache** - After adding templates
❌ **Don't mix content. and node.** - Choose one approach

---

**Full documentation**: https://drupalatyourfingertips.com/twig
