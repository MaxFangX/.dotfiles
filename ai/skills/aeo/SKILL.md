---
name: aeo
description: >-
  Make a public web page readable by AI assistants, browsing agents, and
  their crawlers, so they can find the product's facts and recommend the
  product (answer engine optimization). Use when writing, editing, or
  auditing a landing, pricing, comparison, or docs page meant for the public.
---

# Answer engine optimization

An AI assistant asked "which product should I use?" answers from pages that
it or its crawler has read. A crawler usually fetches only the served HTML,
meaning the HTML as the server returns it, and neither runs scripts nor loads
images. An agent driving a browser reads the page's accessibility tree, not
its pixels. So for these readers a page consists of its machine-readable
text, meaning the text in the served HTML plus the names of its controls in
the accessibility tree.

By default a page is designed to be looked at in a full browser. As a result,
facts end up in images and in elements that a script fills in, controls have
no name, and the copy opens with a slogan. This skill is biased toward stating
every fact as plain text in the served HTML. Check whether each fact is
machine-readable, and treat a fact that has not been checked as missing:

- `curl -s <url>` prints the served HTML, so search the output for the fact.
- An accessibility snapshot, from the browser's developer tools or an
  automation tool, lists each control with its role and name, so look for
  controls with no name.

## Facts in the served HTML

- Pricing, limits, specifications, and proof such as testimonials and usage
  numbers appear as text in the served HTML. Text that a script inserts after
  load is absent from the served HTML:

  ```html
  <!-- Readable -->
  <p>Light and Pro plans take 0% of paid subscription revenue.</p>

  <!-- Not readable -->
  <div id="price"></div>
  <script>
    document.getElementById("price").innerText =
      "Light and Pro plans take 0% of paid subscription revenue.";
  </script>
  ```

- A fact shown in an image is also written out as text on the page. A
  testimonial posted only as a screenshot and a pricing table drawn only as a
  graphic both break this rule.
- Every image, apart from pure decoration, has alt text that describes what
  the image shows, such as "Overhead view of a white horse running".

## Names in the accessibility tree

- Every control that shows only an icon has an accessible name. For example,
  a three-line menu button has `aria-label="Open menu"`.
- Every form field has a `<label>` that names the field, such as "Email" or
  "First name".
- Each functional part of the page uses the native element for its role, such
  as `<nav>`, `<header>`, `<button>`, and `<a>`. A `<div>` that is clicked, or
  that acts as the navigation or a header, breaks this rule:

  ```html
  <!-- Native -->
  <nav>...</nav>
  <button>Book now</button>

  <!-- Not native -->
  <div class="nav">...</div>
  <div class="btn">Book now</div>
  ```

## Copy

- The first sentence that describes the product is a definition, which
  answers three questions: what is the product, who is the product for, and
  what does the product do? For example, "AgencyMax is a CRM for SEO agencies
  that tracks leads, proposals, and existing clients on a single dashboard."
  A slogan such as "Your inbox, reimagined" or "The all-in-one social growth
  platform" answers none of the three questions.
- A page that exists to answer a question, such as a comparison page, a
  pricing page, or a how-to, has that question as its first `<h2>`, directly
  below the `<h1>` and worded as the reader would type the question. For
  example, "Which is better, beehiiv or Substack?"
- The answer follows the question in 100 words or fewer. On a comparison
  page, the answer says which product suits which reader, including the
  reader for whom the competing product is the better choice. For example,
  "If you care about keeping all your subscription revenue, beehiiv is the
  better choice, because beehiiv takes 0% of paid subscriptions and Substack
  takes 10%. Substack works if you want a built-in network to get more
  readers and monetizing isn't a concern."
- A dated article, such as a blog post or an announcement, shows
  "Published <date>" below its title, and "Updated <date>" once its content
  has changed. A page that is revised in place, such as a landing, pricing,
  or docs page, shows no date in its copy, neither "Updated <date>" nor
  "as of <date>" beside a fact: that date goes stale unless someone keeps
  editing it. Keep the page current instead.
- When a page last changed is stated in metadata, which a crawler reads and
  a visitor does not: `<lastmod>` in the sitemap, and `dateModified` in an
  article's structured data. The build fills both from the last commit that
  touched the page, so nobody maintains them.

## Crawling

- `robots.txt` names each AI crawler that should read the site and allows
  that crawler:

  ```
  User-agent: meta-webindexer
  Allow: /
  ```

  Crawler names change, so take each name from the current documentation of
  the crawler's vendor. The live file is at `<domain>/robots.txt`.
- A crawler finds pages by following links, and a broken link returns an
  error instead of a page. So every link on the site resolves. Find broken
  links with a site audit tool such as Screaming Frog, then update, redirect,
  or remove each broken link.
