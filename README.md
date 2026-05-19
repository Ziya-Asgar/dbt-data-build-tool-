# DBT

- [DBT](#dbt)
  - [Some Useful Links](#some-useful-links)
  - [Starting a dbt project in postgreSQL](#starting-a-dbt-project-in-postgresql)
  - [`dbt_project.yml` and `profiles.yml`](#dbt_projectyml-and-profilesyml)
    - [Environment Variables in profiles.yml](#environment-variables-in-profilesyml)
    - [Target and Profile flags](#target-and-profile-flags)
  - [Common dbt commands](#common-dbt-commands)
  - [dbt folders](#dbt-folders)
  - [Models](#models)
    - [Model Configurations](#model-configurations)
    - [Materializations](#materializations)
    - [Model Properties](#model-properties)
    - [Using `ref`](#using-ref)
  - [Sources](#sources)
  - [Tests](#tests)
    - [Data Tests](#data-tests)
      - [Singular data tests](#singular-data-tests)
      - [Generic data tests](#generic-data-tests)
    - [Unit Tests](#unit-tests)
  - [Seeds](#seeds)
  - [Jinja](#jinja)
    - [Variables](#variables)
    - [Conditionals](#conditionals)
    - [White space control](#white-space-control)
    - [Loops](#loops)
    - [Operators](#operators)
    - [Variable Tests](#variable-tests)
    - [dbt Jinja: Filters (aka Methods)](#dbt-jinja-filters-aka-methods)
  - [Macros](#macros)
  - [dbt docs](#dbt-docs)
    - [Generating Documentations](#generating-documentations)
    - [Docs blocks](#docs-blocks)
  - [Packages](#packages)
  - [Hooks](#hooks)

---

---

## Some Useful Links

- [dbt Fundamentals VS Code](https://learn.getdbt.com/courses/dbt-fundamentals-vs-code)
- https://docs.getdbt.com/docs/build/projects?version=1.12

---

---

## Starting a dbt project in postgreSQL

To use dbt we need to download it with the adapter of the database or data warehouse. For example, below command downloads `dbt-core` and the adapter for the postgreSQL database:

```sh
pip install dbt-core dbt-postgres
```

Note: We need to make sure that our python version is compatible with dbt.

Dbt Core is the open-source, Python-based engine that enables data practitioners to transform data. Lately, dbt Labs introduced dbt Fusion, which is faster and provides more features. Both engines could be used for data transformations locally.

After installing dbt Core, create your first dbt project using the `dbt init` command. This initializes a new project with the standard dbt directory structure and helps verify that your installation is working as expected.

```sh
dbt init project_name
```

This command will ask for more details to set up a profile and connection to the database.

If you already have a `profiles.yml` file, where the details of your project's database connection settings are provided, you can exit without providing the details that `dbt init project_name` asks.

After initializing the project, we can check if everything is alright by running the below command in the folder where the project is located:

```sh
dbt debug
```

---

---

## `dbt_project.yml` and `profiles.yml`

We need a `profiles.yml` file that contains the connection details for our data platform. The `profiles.yml` file stores database connection credentials and configuration for dbt projects, including:

- Connection details — Account identifiers, hosts, ports, and authentication credentials.
- Target definitions — Define different environments (dev, staging, prod) within a single profile.
- Default target — Set which environment to use by default.
- Execution parameters — Thread count, timeouts, and retry settings.
- Credential separation — Keep sensitive information out of version control.

If your project has an existing `profiles.yml` file, running `dbt init` will prompt you to amend or overwrite it.

Here is an example `profiles.yml` file:

```yml
# profiles.yml
demodbt_33:
  outputs:
    dev:
      dbname: dbt_db
      host: localhost
      port: 5432
      # dbt will check if the schema already exists when it runs, and create it if it doesn’t
      schema: public
      threads: 1
      type: postgres
      user: postgres
  target: dev
```

Only one `profiles.yml` file is required and it can manage multiple projects and connections. For example, in the below code black, we have different settings for `dev` vs. production projects.

```yml
# profiles.yml
demodbt_33:
  target: dev
  outputs:
    dev:
      dbname: dbt_db
      host: localhost
      port: 5432
      # dbt will check if the schema already exists when it runs, and create it if it doesn’t
      schema: public
      threads: 1
      type: postgres
      user: postgres

    prod:
      dbname: dbt_prod_db
      ...
```

dbt Core searches for the parent directory of `profiles.yml` in the following order and uses the first location it finds:

1. `--profiles-dir` flag
2. `DBT_PROFILES_DIR` environment variable
3. Current working directory
4. `~/.dbt/` directory (Recommended location)

> Note: dbt Core supports using the `DBT_PROFILES_DIR` environment variable or a `profiles.yml` file in the current working directory. These options aren't currently supported in Fusion.

Another important file - `dbt_project.yml` - is linked to the `profiles.yml` file. The `profile` field in `dbt_project.yml` references the profile name defined in `profiles.yml`. For example, below part from an example `dbt_project.yml` file uses `demodbt_33` as a profile, which is the same profile name used in the above example:

```yml
# dbt_project.yml
# ...
# This setting configures which "profile" dbt uses for this project.
profile: "demodbt_33"

# ...
```

---

### Environment Variables in profiles.yml

It's recommended to use environment variables to keep sensitive credentials out of your `profiles.yml` file. In the below example, we use the [`env_var`](https://docs.getdbt.com/reference/dbt-jinja-functions/env_var?version=1.12) to incorporate the environment variables into our `profiles.yml` file.

```yml
# `profiles.yml` - Best Practices
demodbt_33:
  target: dev # Default target when running dbt without --target flag
  outputs:
    dev:
      type: postgres
      # IMPORTANT: Make sure to quote the entire Jinja string here
      host: "{{ env_var('DBT_HOST') }}" # Required
      user: "{{ env_var('DBT_USER') }}" # Required
      password: "{{ env_var('DBT_PASSWORD') }}" # Required
      port: "{{ env_var('DBT_PORT', '5432') }}" # Optional with default
      dbname: "{{ env_var('DBT_DATABASE') }}" # Required
      schema: "{{ env_var('DBT_SCHEMA') }}" # Required
      threads: "{{ env_var('DBT_THREADS', '4') }}" # Optional with default
      keepalives_idle: 120 # Additional config
```

There are different ways of setting environment variables. If you'd like to set temporary (for current command prompt session) environment variables on Windows, you can run below commands on a command line:

```sh
set DBT_HOST=localhost
set DBT_USER=postgres
set DBT_PASSWORD=your_actual_password
set DBT_PORT=5432
set DBT_DATABASE=demodbt_33
set DBT_SCHEMA=public
set DBT_THREADS=4
```

Another way of setting environment variables for dbt projects is to create a file named `.env` in the project directory and having the following content in it:

```env
# Database connection settings
DBT_HOST=localhost
DBT_USER=postgres
DBT_PASSWORD=your_actual_password
DBT_PORT=5432
DBT_DATABASE=demodbt_33
DBT_SCHEMA=public
DBT_THREADS=4
```

We need to have `python-dotenv` package to load the environment variables. We can run the below command to install it:

```sh
pip install python-dotenv
```

After this, we can use the `.env` file with this command:

```sh
python -m dotenv run dbt debug
```

This command performs two main actions in sequence:

- `python -m dotenv` part tells Python to run the `dotenv` module to read the `.env` file and set all the environment variables defined in it. It temporarily loads these variables into your current command session.
- `run dbt debug` part runs the `dbt debug` command using the environment variables that were just loaded. The `run` part is a subcommand of `dotenv` that executes whatever follows it.

So it's essentially saying: "Load the `.env` file, then `run dbt debug` with those variables"

> Note: Remember to add the `.env` file to the `.gitignore` file, so that your important data added to the `.env` file is not shared with everyone, when you push your project to a public repository

---

### Target and Profile flags

dbt supports multiple targets within one profile to encourage the use of separate development and production environments. When running dbt commands, you can specify which profile and target to use from the CLI using the `--profile` and `--target` flags.

- `--profile` flag - Overrides the profile set in `dbt_project.yml` by pointing to another profile defined in `profiles.yml`.
- `--target` flag - Specifies the target within that profile to use (as defined in `profiles.yml`).

These flags help when you're working with multiple profiles and targets and want to override defaults without changing your files.

```sh
dbt run --profile my-profile-name --target dev
```

A typical profile for an analyst using dbt locally will have a target named `dev`, and have this set as the default. For example, to run against your `prod` target instead of the default `dev` target:

```sh
dbt run --target prod
```

You can use the `--target` flag with any dbt command, such as:

```sh
dbt build --target prod
dbt test --target dev
```

---

---

## Common dbt commands

In dbt, the commands you commonly use are:

- `dbt run` — Run the models you defined in your project
- `dbt build` — Build and test your selected resources such as models, seeds, snapshots, and tests
- `dbt test` — Execute the tests you defined for your project

For all dbt commands and their arguments (flags), see the [dbt command reference](https://docs.getdbt.com/reference/dbt-commands?version=1.12).

To list all dbt commands from the command line, run `dbt --help`.

To list a specific command's arguments, run `dbt COMMAND_NAME --help`.

---

---

## dbt folders

The default dbt project (created after the `dbt init` command) comes with the below folder structure:

- The macros are blocks of code that you can reuse multiple times (similar to functions in programming languages). In the default folder structure of dbt, there is a folder named **macros** to store all the macros.
- The **models** folder includes all the data models for a project.
- The **target** folder includes the compiled SQL.
  - The **run** folder shows the `create or replace` table statements that are running
- The **logs** folder includes information on how dbt Core logs all of the action happening within your project.
- The **snapshots** folder captures the state of your mutable tables so you can refer to it later.
- The **seeds** folder includes CSV files with static data that you can load into your data platform with dbt.

---

---

## Models

Models, in dbt, are generally SQL scripts with jinja (Starting in version 1.3, dbt Core and dbt support Python models). Each model lives in a single file and contains logic that either transforms raw data into a dataset that is ready for analytics or, more often, is an intermediate step in such a transformation.

When you execute `dbt run`, you are running a model that will transform your data without that data ever leaving your warehouse. Models are primarily written as a `select` statement and saved as a `.sql` file.

To practice on a building a simple model, let's say we have `orders` and `customers` table in a postgreSQL database schema called `raw`. We can create the below model to transform the data.

```sql
-- models/order_summary/order_summary.sql
WITH order_data as (
  SELECT
    order_id,
    customer_id,
    order_date,
    status,
    total_amount
  FROM
    raw.orders
),
customer_orders as (
  SELECT
    customer_id,
    COUNT(*) as total_orders,
    SUM(total_amount) as lifetime_value,
    MAX(order_date) as last_order_date
  FROM
    order_data
  GROUP BY
    customer_id
),
final as (
  SELECT
    co.customer_id,
    co.total_orders,
    co.lifetime_value,
    co.last_order_date,
    CASE
      WHEN co.lifetime_value > 500 THEN 'Premium'
      WHEN co.lifetime_value > 200 THEN 'Gold'
      ELSE 'Regular'
    END AS customer_tier
  FROM
    customer_orders co
)

SELECT *
FROM FINAL
ORDER BY lifetime_value DESC
```

---

### Model Configurations

Configurations are "model settings" that you can set in your `dbt_project.yml` file, and in your model file using a `config` block. By default dbt will:

- Create models as views
- Build models in a target schema you define
- Use your file name as the view or table name in the database

For example, below configuration shows that we want the models in the `order_summary` directory to materialize as views.

```yml
# dbt_project.yml
# ...
models:
  demodbt_33:
    # Config indicated by + and applies to all files under models/order_summary/
    order_summary:
      +materialized: view
```

We can use the `config` macro to override the configuration in the `dbt_project.yml` file. For example, if we add `{{ config(materialized='table') }}` to the `order_summary.sql` file, the `config` will override the configuration set in the `dbt_project.yml` file.

```sql
-- models/order_summary/order_summary.sql
{{config(materialized='table')}}

WITH order_data as (
  SELECT
    order_id,
    ...
```

Instead of using different `config` macros in the model sql files, we can have different materializations for different folders set up in the `dbt_project.yml` file. In the below example, we indicate that we want all the models to be materialized as views except the models in the `order_summary` directory. But we don't want all models in the `order_summary` directory to materialize as tables. We want the `daily_orders` directory, within the `order_summary` directory to be materialized as view:

```yml
# dbt_project.yml
# ...
models:
  demodbt_33: # this matches the `name:`` config
    +materialized: view # this applies to all models in the current project
    order_summary:
      +materialized: table # this applies to all models in the `order_summary/` directory
      daily_orders:
        +materialized: view # this applies to all models in the `order_summary/daily_orders/`` directory
```

Here is the daily_orders model:

```sql
-- models/order_summary/daily_orders
with daily_orders as (
  SELECT
    order_date,
    COUNT(*) as total_orders,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as average_order_value
  FROM
    raw.orders
  WHERE order_date >= '2023-01-01'
  GROUP BY order_date
),
final as (
  SELECT
    order_date,
    total_orders,
    total_revenue,
    round(average_order_value) as average_order_value,
    CASE
      WHEN total_revenue > 1000 THEN 'High Revenue Day'
      WHEN total_revenue > 500 THEN 'Medium Revenue Day'
      ELSE 'Low Revenue Day'
    END as revenue_category
  FROM daily_orders
)

SELECT *
FROM final
ORDER BY order_date
```

It is important to note that configurations are applied hierarchically - a configuration applied to a subdirectory will override any general configurations.

Now, we can run dbt to execute our models:

```sh
# Run all the models
dbt run

# Run just this specific model
dbt run --select order_summary.daily_orders

# Or run all models in the order_summary directory
dbt run --select order_summary
```

---

### Materializations

Materializations are strategies for persisting dbt models in a warehouse. These are the materialization types built into dbt:

- `ephemeral` — ephemeral models are not directly built into the database
- `table` — a model is rebuilt as a table on each run
- `view` — a model is rebuilt as a view on each run
- `materialized_view` — allows the creation and maintenance of materialized views in the target database. Materialized views are a combination of a view and a table, and serve use cases similar to incremental models.
- `incremental` — incremental models allow dbt to insert or update records into a table since the last time that model was run

You can also configure custom materializations in dbt. Custom materializations are a powerful way to extend dbt's functionality to meet your specific needs.

---

### Model Properties

`model-paths` in the `dbt_project.yml` file indicates the folder that includes models:

```yml
# dbt_project.yml
# ...
model-paths: ["models"]
# ...
```

In addition to indicating which folder includes our models in the `dbt_project.yml` file, we can create `.yml` files in our `models/` directory (as defined by the `model-paths` config) to set the model properties. You can name these files `_whatever_you_want.yml_`, and nest them arbitrarily deeply in subfolders within the `models/` directory. One example for a `.yml` file in the `models/` directory is the file called `schema.yml`, which is created in the default folder structure, after we initialize a dbt project with `dbt init`.

Here are a few model properties that we can have in the `.yml` files:

- `name` - accepts a string as value. It's a **required** property. The name must match the model filename.
- `description` - accepts a string as value. It's **not** a required property. It's a documentation for the model.
- `columns` - accepts an array as value. It's **not** a required property. It is a list of column definitions.
- `config` - accepts an object as value. It's **not** a required property. It defines model configuration (materialization, tags, etc.).
- `constraints` - accepts an array as value. It's **not** a required property. It defines model-level constraints (primary key, foreign key, etc.).
- `data_tests` - accepts an array as value. It's **not** a required property. It defines model-level data tests.

The below item is to show how many different model properties we can set:

```yml
models:
  # Model name must match the filename of a model -- including case sensitivity
  - name: model_name
    description: <markdown_string>
    latest_version: <version_identifier>
    deprecation_date: <YAML_DateTime>
    config:
      <model_config>: <config_value>
      docs:
        show: true | false
        node_color: <color_id> # Use name (such as node_color: purple) or hex code with quotes (such as node_color: "#cd7f32")
      access: private | protected | public
    constraints:
      - <constraint>
    data_tests:
      - <test>
      - ... # declare additional data tests
    columns:
      - name: <column_name> # required
        description: <markdown_string>
        quote: true | false
        constraints:
          - <constraint>
        data_tests:
          - <test>
          - ... # declare additional data tests
        config:
          meta: {<dictionary>}
          tags: [<string>]

        # only required in conjunction with time_spine key
        granularity: <any supported time granularity>

      - name: ... # declare properties of additional columns

    time_spine:
      standard_granularity_column: <column_name>

    versions:
      - v: <version_identifier> # required
        defined_in: <definition_file_name>
        description: <markdown_string>
        constraints:
          - <constraint>
        config:
          <model_config>: <config_value>
          docs:
            show: true | false
          access: private | protected | public
        data_tests:
          - <test>
          - ... # declare additional data tests
        columns:
          # include/exclude columns from the top-level model properties
          - include: <include_value>
            exclude: <exclude_list>
          # specify additional columns
          - name: <column_name> # required
            quote: true | false
            constraints:
              - <constraint>
            data_tests:
              - <test>
              - ... # declare additional data tests
            tags: [<string>]
        - v: ... # declare additional versions
```

Here is an example `.yml` file for the models that we created above:

```yml
# models/order_summary/model_properties.yml
version: 2

models:
  # This corresponds to the order_summary.sql model
  - name: order_summary
    description: "Summary of customer orders with key metrics"
    config:
      materialized: table
      # Below line will create a schema called `raw_analytics`. This is because we have set `schema: raw` in the `profiles.yml` file.
      schema: "analytics"
      tags: ["orders", "summary"]
    columns:
      - name: customer_id
        description: "Unique identifier for a customer"
        data_tests:
          - not_null
          - unique
      - name: total_orders
        description: "Total number of orders placed by a customer"
      - name: lifetime_value
        description: "Total revenue generated by a customer"
      - name: last_order_date
        description: "Date of a customer's most recent order"

  # This corresponds to the daily_orders.sql model
  - name: daily_orders
    description: "Daily aggregation of order metrics"
    config:
      materialized: table
      tags: ["orders", "daily"]
      schema: "analytics"
    columns:
      - name: order_date
        description: "Date when an order was placed"
        data_tests:
          - not_null
      - name: total_orders
        description: "Number of orders placed on a specific date"
      - name: total_revenue
        description: "Total revenue generated on a specific date"
      - name: average_order_value
        description: "Average value of orders placed on a specific date"
      - name: revenue_category
        description: "Categories based on the amount revenue in a day"
```

In the above example `.yml` file, we have `tags` as well. These could be useful to tag and run specific models. Here are example commands using `tags`:

```sh
# Run only models with the 'orders' tag
dbt run --select tag:orders

# Run models with multiple tags
dbt run --select tag:orders tag:daily

# Run all models except those with the 'deprecated' tag
dbt run --exclude tag:deprecated

# Run models with the 'analytics' tag and their dependencies
dbt run --select tag:analytics --select +tag:analytics
```

---

### Using `ref`

We can build dependencies between models by using the `ref` function in place of table names in a query. We use the name of another model as the argument for `ref` to achieve this:

```sql
-- models/order_summary/customer_segmentation.sql

-- This model references the order_summary model using ref macro
WITH customer_segments AS (
  SELECT
    customer_id,
    total_orders,
    lifetime_value,
    last_order_date,
    customer_tier
  FROM {{ ref('order_summary') }}  -- References the order_summary model
)

SELECT
  customer_tier,
  COUNT(*) AS customer_count,
  ROUND(AVG(lifetime_value), 2) AS avg_lifetime_value,
  SUM(lifetime_value) AS total_lifetime_value
FROM customer_segments
GROUP BY customer_tier
ORDER BY total_lifetime_value DESC
```

Now, we can run `dbt run --select customer_segmentation`. With this command:

- dbt will first run `order_summary`,
- then `customer_segmentation` which references `order_summary`

The `ref('order_summary')` macro gets replaced with the actual SQL. To check the compiled SQL, we can go to the `target/compiled/demodbt_33/models/order_summary/customer_segmentation.sql` file.

---

---

## Sources

Sources are defined in `.yml` files nested under the `sources` key. The `sources` could be in the same file as the model properties but it's not recommended. With `sources`, we provide the data (db, schema, tables) to be transformed. Declaring these tables as sources in dbt, helps to

- select from source tables using the `{{ source() }}` function,
- test the assumptions about the source data,
- calculate the freshness of the source data.

Here is an example file:

```yml
# models/sources.yml
version: 2

sources:
  - name: raw_data # This is the "Source Name" used in {{ source() }}
    schema: raw # This tells dbt to look in the 'raw' schema in the db
    tables:
      - name: orders # This is the actual table name in the db
        description: "Raw orders data imported from CSV"
```

Here is an example of using a source in a model:

```sql
-- models/order_summary/order_summary.sql
{{config(materialized='table')}}

WITH order_data as (
  SELECT
    order_id,
    customer_id,
    order_date,
    status,
    total_amount
  FROM
    {{ source('raw_data', 'orders') }}  -- Changed from raw.orders
),

customer_orders as (
  SELECT
    customer_id,
    COUNT(*) as total_orders,
    SUM(total_amount) as lifetime_value,
    MAX(order_date) as last_order_date
  FROM
    order_data
  GROUP BY
    customer_id
),

final as (
  SELECT
    co.customer_id,
    co.total_orders,
    co.lifetime_value,
    co.last_order_date,
    CASE
      WHEN co.lifetime_value > 500 THEN 'Premium'
      WHEN co.lifetime_value > 200 THEN 'Gold'
      ELSE 'Regular'
    END AS customer_tier
  FROM
    customer_orders co
)

SELECT *
FROM final
```

We can also:

- Add data tests to sources
- Add descriptions to sources, that get rendered as part of the documentation site
- Have more than one source in the source `.yml` file

Here is an example of adding and using more than one source:

```yml
version: 2

sources:
  - name: raw_data
    schema: raw
    tables:
      - name: orders
        description: "Raw orders data imported from CSV"
      - name: customers # Added the customers table here
        description: "Raw customer profile data"
```

Here is another use of the `source` function, now together with the `ref` function:

```sql
-- models/order_summary/customer_segmentation.sql

{{ config(
    materialized='table',
    schema='analytics'
) }}

WITH customer_raw AS (
  SELECT
    customer_id,
    customer_name,
    city,
    country
  FROM {{ source('raw_data', 'customers') }} -- Using the new source here
),

customer_segments AS (
  SELECT
    customer_id,
    total_orders,
    lifetime_value,
    last_order_date,
    customer_tier
  FROM {{ ref('order_summary') }} -- Referencing the previous model
)

SELECT
    cs.customer_tier,
    cr.city,
    cr.country,
    COUNT(cs.customer_id) AS customer_count,
    ROUND(AVG(cs.lifetime_value), 2) AS avg_lifetime_value,
    SUM(cs.lifetime_value) AS total_lifetime_value
FROM customer_segments cs
JOIN customer_raw cr ON cs.customer_id = cr.customer_id
GROUP BY
    cs.customer_tier,
    cr.city,
    cr.country,
ORDER BY total_lifetime_value DESC
```

---

---

## Tests

### Data Tests

Data tests are assertions you make about your models and other resources in your dbt project (for example, sources, seeds, and snapshots). When you run `dbt test`, dbt will tell you if each test in your project passes or fails.

You can use data tests to improve the integrity of the SQL in each model by making assertions about the results generated. Out of the box, you can test whether a specified column in a model only contains non-null values, unique values, or values that have a corresponding value in another model.

Like almost everything in dbt, data tests are SQL queries. In particular, they are `select` statements that seek to grab "failing" records, ones that disprove your assertion. If you assert that a column is unique in a model, the test query selects for duplicates; if you assert that a column is never null, the test seeks after nulls. If the data test returns zero failing rows, it passes, and your assertion has been validated.

There are two ways of defining data tests in dbt:

- A **singular** data test is testing in its simplest form: If we can write a SQL query that returns failing rows, we can save that query in a `.sql` file within your test directory. It's now a data test, and it will be executed by the `dbt test` command.
- A **generic** data test is a parameterized query that accepts arguments.

---

#### Singular data tests

The simplest way to define a data test is by writing the exact SQL that will return failing records. We call these "singular" data tests, because they're one-off assertions usable for a single purpose.

These tests are defined in `.sql` files, typically in the **tests** directory (as defined by the `test-paths` config). We can use Jinja (including `ref` and `source`) in the test definition, just like we can when creating models. Each `.sql` file contains one `select` statement, and it defines one data test:

```sql
-- The name of this test is the name of the file: assert_ltv_is_positive
-- The lifetime value of a customer should not be < 0.
-- Therefore return records where lifetime value < 0 to make the test fail.
SELECT
    customer_id,
    lifetime_value
FROM {{ ref('order_summary') }}
WHERE lifetime_value < 0
```

Note:

- Omit semicolons (`;`) at the end of the SQL statement in singular test files, as they can cause data test to fail.
- Singular data tests placed in the **tests** directory are automatically executed when running `dbt test`. Don't reference singular tests in `model_name.yml`, as they are not treated as generic tests or macros, and doing so will result in an error.

To add a description to a singular data test in the project, add a `.yml` file to the **tests** directory. For example:

```yml
# tests/schema.yml
data_tests:
  - name: assert_ltv_is_positive
    description: >
      The lifetime value of a customer should not be < 0.
      Therefore, return records where lifetime value < 0 to make the test fail.
```

---

#### Generic data tests

Certain data tests are generic: they can be reused over and over again. A generic data test is defined in a test block, which contains a parameterized query and accepts arguments. It might look like this:

```sql
{% test not_null(model, column_name) %}

    select *
    from {{ model }}
    where {{ column_name }} is null

{% endtest %}
```

Once that generic test has been defined, it can be added as a property on any existing model (or source, seed, or snapshot). These properties are added in `.yml` files in the same directory as the resource.

Out of the box, dbt ships with four generic data tests already defined:

- `unique`,
- `not_null`,
- `accepted_values`, and
- `relationships`.

Here's a full example using those tests on an `orders` model:

```yml
# models/order_summary/model_properties.yml
version: 2

models:
  # This corresponds to the order_summary.sql model
  - name: order_summary
    description: "Summary of customer orders with key metrics"
    config:
      materialized: table
      tags: ["orders", "summary"]
      schema: "analytics" # we have set `schema: raw` in the `profiles.yml` file. Therefore, this line will create a schema called `raw_analytics`
    columns:
      - name: customer_id
        description: "Unique identifier for the customer"
        data_tests:
          - not_null
          - unique
          - relationships:
              to: source('raw_data', 'orders')
              field: customer_id
        # ...

  # This corresponds to the daily_orders.sql model
  - name: daily_orders
    description: "Daily aggregation of order metrics"
    config:
      materialized: table
      tags: ["orders", "daily"]
      schema: "analytics"
    columns:
      # ...
      - name: revenue_category
        description: "Categories based on the amount revenue in a day"
        data_tests:
          - accepted_values:
              values:
                ["High Revenue Day", "Medium Revenue Day", "Low Revenue Day"]
```

Let's now write our own generic test. Generic tests must be written as macros. Generic tests are defined in SQL files. Those files can live in two places:

- `tests/generic/`: that is, a special subfolder named **generic** within the specified test paths
- `macros/`: Why? Generic tests work a lot like macros, and historically, this was the only place they could be defined. If the generic test depends on complex macro logic, it might be more convenient to define the macros and the generic test in the same file.

The main rule of dbt tests is that the query must return the rows that fail. If the query returns zero rows, the test passes.

```sql
-- tests/generic/test_is_positive.sql
{% test is_positive(model, column_name) %}

with validation_errors as (
    select
        {{ column_name }} as amount
    from {{ model }}
    where {{ column_name }} < 0
)

select *
from validation_errors

{% endtest %}
```

Now, we can use `is_positive` just like built-in generic tests `unique` or `not_null`.

```yml
# models/order_summary/model_properties.yml
version: 2

models:
  # This corresponds to the order_summary.sql model
  - name: order_summary
    # ...
    columns:
      # ...
      - name: total_orders
        description: "Total number of orders placed by the customer"
        data_tests:
          - is_positive # <--- Using our custom generic test!
      - name: lifetime_value
        description: "Total revenue generated by the customer"
        data_tests:
          - is_positive # <--- Reusing the same test on a different column!
      # ...
```

We can also add information about the generic test to the `tests/schema.yml` file:

```yml
# tests/schema.yml
data_tests:
  - name: test_is_positive
    description: The value should not be < 0. Therefore return records where value < 0 to make the test fail.
```

Now, we can run `dbt test`. We can also run the test specifically on some model with the below command:

```sh
dbt test --select order_summary
```

Let's now write a generic test that accepts arguments. In the previous example, we only used the implicit arguments. Every generic test automatically receives two arguments from dbt: `model` and `column_name`. When we wrote - `is_positive` in the `.yml` file, dbt looked at which column it was under (`lifetime_value`) and which model it belonged to (`order_summary`) and passed those values into the macro automatically. We will add a third argument called `threshold`. We will also give it a default value of `0`, so that if we don't provide a threshold, it behaves like our previous "positive" test.

```sql
-- tests/generic/test_is_greater_than.sql
{% test is_greater_than(model, column_name, threshold = 0) %}

WITH validation_errors AS (
  SELECT
    {{ column_name }} AS amount
  FROM {{ model }}
  WHERE {{ column_name }} <= {{ threshold }}
)

SELECT * FROM validation_errors

{% endtest %}
```

```yml
# models/order_summary/model_properties.yml
version: 2

models:
  # This corresponds to the order_summary.sql model
  - name: order_summary
    # ...
    columns:
      # ...

      # This corresponds to the daily_orders.sql model
  - name: daily_orders
    description: "Daily aggregation of order metrics"
    config:
      materialized: table
      tags: ["orders", "daily"]
      schema: "analytics"
    columns:
      # ...
      - name: total_orders
        description: "Number of orders placed on that date"
        data_tests:
          - is_greater_than # Use the default (0). Fails if orders <= 0
      - name: total_revenue
        description: "Total revenue generated on that date"
        data_tests:
          - is_greater_than:
              arguments:
                threshold: 10
      # ...
```

```yml
# tests/schema.yml
data_tests:
  - name: assert_ltv_is_positive
    description: >
      The lifetime value of a customer should not be < 0.
      Therefore, return records where lifetime value < 0 to make the test fail.
  - name: test_is_positive
    description: >
      The value should not be < 0.
      Therefore return records where value < 0 to make the test fail.
  - name: test_is_greater_than
    description: The value should not be < a specified threshold.
    arguments:
      - name: model
        type: string
        description: Model Name
      - name: column_name
        type: string
        description: Column name that should not be an empty string
      - name: threshold
        type: string
        description: Threshold that the column value is supposed to be above
```

---

### Unit Tests

Historically, dbt's test coverage was confined to “data” tests, assessing the quality of input data or resulting datasets' structure. However, these tests could only be executed after building a model.

There is an additional type of test in dbt - unit tests. In software programming, unit tests validate small portions of your functional code, and they work much the same way here. Unit tests allow to validate the SQL modeling logic on a small set of static inputs before you materialize your full model in production.

Unit tests must be defined in a `.yml` file in the `models/` directory.

dbt Labs strongly recommends only running unit tests in development or CI environments. Since the inputs of the unit tests are static, there's no need to use additional compute cycles running them in production. Use them in development for a test-driven approach and CI to ensure changes don't break them.

---

---

## Seeds

Seeds are CSV files in your dbt project (typically in your seeds directory), that dbt can load into your data warehouse using the `dbt seed` command. Seeds can be referenced in downstream models the same way as referencing models — by using the `ref` function.

To load a seed file in your dbt project:

- Add the file to your seeds directory, with a .csv file extension
- Run the `dbt seed` command — a new table will be created in your warehouse in your target schema
- Refer to seeds in downstream models using the `ref` function.

In the below example, we are referring to a table seeded with csv and `dbt seed` command.

```sql
-- models/customer_counts_by_region/customer_counts_by_region.sql
with customers as (
    select * from {{ source('raw_data', 'customers') }}
),

regions as (
    select * from {{ ref('country_regions') }}
)

select
    r.region,
    count(c.customer_id) as total_customers
from customers c
join regions r on c.country = r.country
group by r.region
order by total_customers desc
```

```yml
# models/customer_counts_by_region/schema.yml
version: 2

models:
  # This corresponds to the customer_with_codes.sql model
  - name: customer_counts_by_region
    description: "number of customers by region"
    config:
      materialized: table
      tags: ["orders", "summary", "regions"]
      schema: "analytics" # we have set `schema: raw` in the `profiles.yml` file. Therefore, this line will create a schema called `raw_analytics`
    columns:
      - name: region
        description: "regions of customers"
        data_tests:
          - relationships:
              to: source('raw_data', 'country_regions')
              field: region
      - name: total_customers
        description: "total number of customers"
```

You can check out the [seed configurations docs](https://docs.getdbt.com/reference/seed-configs?version=1.12) for a full list of available configurations.

---

---

## Jinja

In dbt, you can combine SQL with Jinja, a templating language. Jinja can be used in any SQL in a dbt project, including models, analyses, data tests, and even hooks.

In Jinja, we have:

- **Statements** `{% ... %}`: Statements don't output a string. They are used for control flow, for example, to set up `for` loops and `if` statements, to set or modify variables, or to define macros.
- **Expressions** `{{ ... }}`: Expressions are used when you want to output a string. You can use expressions to reference variables and call macros.
- **Comments** `{# ... #}`: Jinja comments are used to prevent the text within the comment from executing or outputing a string. Don't use `--` for comment.

When used in a dbt model, your Jinja needs to compile to a valid query. To check what SQL your Jinja compiles to, using dbt Core, run `dbt compile` from the command line. Then open the compiled SQL file in the `target/compiled/{project name}/` directory.

---

### Variables

In the below example, we set three variables: a basic string, an array, and a dictionary. Then, we use them in our SQL code:

```jinja
{% set string_var = 'string 1' %}
{% set list_var = ['list_var 1', 'list_var 2'] %}
{% set dict_var = {'dict_key1': 'dict_val1', 'dict_key2': 'dict_val2'} %}

SELECT
  '{{ string_var }}' AS column1,

  {# we are using dollar-quoted strings sometimes to escape single quotes of string values #}
  $${{ list_var }}$$ AS column2,
  '{{ list_var[0] }}' AS column2_1,
  $${{dict_var}}$$ AS column3,
  $${{dict_var['dict_key1']}}$$ AS column3_1,
  '{{dict_var.dict_key2}}' AS column3_2
```

---

### Conditionals

Here is an example of using `if`, `elif`, `else`, and `endif` control flow statement. Note that Jinja requires an explicit `{% endif %}` to know exactly where the conditional block closes:

```jinja
{% set environment = 'dev' %}

SELECT
  '{{ environment }}' AS current_env,

  {% if environment == 'dev' %}
    'This is a development environment' AS run_type,
  {% elif environment == 'prod' %}
    'This is a production environment' AS run_type,
  {% else %}
    'This is an unknown environment' AS run_type,
  {% endif%}

  'Run complete' AS status
```

---

### White space control

Jinja allows control over white spaces in the compiled output. For example, when we run the `if` block in the previous section, we get the below code in the compiled output:

```sql
SELECT
  'dev' AS current_env,


    'This is a development environment' AS run_type,


  'Run complete' AS status
```

We can use `-` to get rid of the white spaces in the compiled code. To strip the white space from the beginning, we use `{%- ... %}`. Here is an example and the output:

```jinja
{% set environment = 'dev' %}

SELECT
  '{{ environment }}' AS current_env,

  {%- if environment == 'dev' %}
    'This is a development environment' AS run_type,
  {% elif environment == 'prod' %}
    'This is a production environment' AS run_type,
  {% else %}
    'This is an unknown environment' AS run_type,
  {% endif%}

  'Run complete' AS status
```

```sql
SELECT
  'dev' AS current_env,
    'This is a development environment' AS run_type,


  'Run complete' AS status
```

To strip the white space from the end, we use `{% ... -%}`. Here is an example and the output:

```jinja
{% set environment = 'dev' %}

SELECT
  '{{ environment }}' AS current_env,

  {% if environment == 'dev' %}
    'This is a development environment' AS run_type,
  {% elif environment == 'prod' %}
    'This is a production environment' AS run_type,
  {% else %}
    'This is an unknown environment' AS run_type,
  {% endif -%}

  'Run complete' AS status
```

```sql


SELECT
  'dev' AS current_env,


    'This is a development environment' AS run_type,
  'Run complete' AS status
```

To strip the white space from the both sides, we use `{%- ... -%}`. Here is an example and the output:

```jinja
{% set environment = 'dev' %}

SELECT
  '{{ environment }}' AS current_env,

  {%- if environment == 'dev' %}
    'This is a development environment' AS run_type,
  {% elif environment == 'prod' %}
    'This is a production environment' AS run_type,
  {% else %}
    'This is an unknown environment' AS run_type,
  {% endif -%}

  'Run complete' AS status
```

```sql
SELECT
  'dev' AS current_env,
    'This is a development environment' AS run_type,
  'Run complete' AS status
```

Not that you must not add whitespace between the tag and the minus sign in the jinja code. This won't work: `{% - ... %}`

---

### Loops

Here is an example of using a `for` loop:

```jinja
{% set colors = ['red', 'blue', 'green'] %}

{% for color in colors %}
  SELECT '{{ color }}' AS color_name
  UNION ALL
{% endfor %}

  SELECT 'Loop ended'
```

There are some loop properties that we can access in Jinja:

- `loop.first` - is True if the current iteration is the first iteration.
- `loop.last` - is True if the current iteration is the last iteration.
- `loop.index` - An integer representing the current iteration of the loop (1-indexed). So, the first iteration would have `loop.index` of 1, the second would be 2, and so on.

Here is a simple example of using these properties:

```jinja
{%- set nums = ['first', 'second', 'third'] -%}

  SELECT
    {% for num in nums -%}

      {%- if loop.first -%}
        '{{ num }}' AS first,
      {%- endif %}

      '{{ loop.index }}' AS loop_index_{{ loop.index }},

      {%- if loop.last -%}
      '{{ num }}' AS last,
      {%- endif %}

    {%- endfor %}

  'Loop ended' AS loop_end
```

Here is an example of looping through a dictionary:

```jinja
{% set user_info = {'name': 'John', 'city': 'New York', 'role': 'Admin'} %}

{% for key, value in user_info.items() %}
  SELECT '{{ key }}' AS attribute, '{{ value }}' AS detail

  {%- if not loop.last %}
    UNION ALL
  {% endif -%}
{% endfor %}
```

If we don't use the `items` method, the `for` loop will only loop through the dictionary keys:

```jinja
{% set user_info = {'name': 'John', 'city': 'New York', 'role': 'Admin'} %}

{% for key in user_info %}
  SELECT '{{ key }}' AS attribute, '{{ user_info[key] }}' AS detail

  {%- if not loop.last %}
    UNION ALL
  {% endif -%}
{% endfor %}
```

---

### Operators

There are 3 logical operators in dbt:

- `and`
- `or`
- `not`

Here is an example of using all three:

```jinja
{% set user_role = 'admin' %}
{% set is_active = true %}
{% set is_banned = false %}

SELECT
  {% if user_role == 'admin' and is_active %}
    'Access Granted' AS status,
  {% elif user_role == 'guest' or is_active == false %}
    'Limited Access' AS status,
  {% elif not is_banned %}
    'Standard Access' AS status,
  {% else %}
    'No Access' AS status,
  {% endif %}

  'User Check Complete' AS check_log
```

There are 6 comparison operators in dbt:

- `==` - Equal To
- `!=` - Not Equal To
- `>` - Greater Than
- `<` - Less Than
- `>=` - Greater Than or Equal to
- `<=` - Less Than or Equal To

Here is a simple example using all of them:

```jinja
{% set current_value = 10 %}

SELECT
  {% if current_value == 10 %} 'Equal to 10' {% endif %} AS test_eq,
  {% if current_value != 5 %}  'Not equal to 5' {% endif %} AS test_neq,
  {% if current_value > 2 %}   'Greater than 2' {% endif %} AS test_gt,
  {% if current_value < 20 %}  'Less than 20' {% endif %} AS test_lt,
  {% if current_value >= 10 %} 'Greater or equal to 10' {% endif %} AS test_gte,
  {% if current_value <= 11 %}  'Less or equal to 9' {% endif %} AS test_lte
```

---

### Variable Tests

Within dbt, you may need to validate if a variable is defined or a if a value is odd or even. These Jinja Variable tests allow you to validate with ease.

- `Is Defined`
- `Is None`
- `Is Even`
- `Is Odd`
- `Is a String`
- `Is a Number`

Here is a simple example demonstrating all of these tests:

```jinja
{% set my_num = 10 %}
{% set my_string = "Hello" %}
{% set my_none = none %}

SELECT
  {% if my_num is defined %} 'Defined' AS test_defined, {% endif %}
  {% if my_none is none %}   'Is None' AS test_none,   {% endif %}
  {% if my_num is even %}    'Is Even' AS test_even,   {% endif %}
  {% if my_num is odd %}     'Is Odd' AS test_odd,    {% endif %}
  {% if my_string is string %} 'Is String' AS test_string, {% endif %}
  {% if my_num is number %}  'Is Number' AS test_number  {% endif %}
```

---

### dbt Jinja: Filters (aka Methods)

Jinja filters in dbt allow you to transform variables and expressions during the compilation phase using the pipe symbol (`|`).

- `lower` / `upper`: Converts text to lowercase or uppercase.

```jinja
{% set arr = ["first_name" , "last_name"] %}

SELECT
  '{{ "TEST" | lower }}' as col_lower,
  '{{ "test" | upper }}' as col_upper,
  '{{ none | default("default_value") }}' as col_default,
  '{{ arr | join("-") }}' as col_join,
  '{{ "hello" | replace("hello" , "bye") }}' as col_replace,
  '{{ " text_with_whitespace " | trim }}' as  col_trim
```

---

---

## Macros

Macros in Jinja are pieces of code that can be reused multiple times – they are analogous to "functions" in other programming languages. Macros are defined in .sql files, typically in your macros directory (docs).

Macro files can contain one or more macros. We define macros like this:

```jinja
<!-- macros/numbers_in_thousands.sql -->
{% macro numbers_in_thousands( column_name, round_to=0) %}
  round(
    {{ column_name }} / 1000,
    {{ round_to }}
  )
{% endmacro %}
```

We use the macros like this:

```jinja
<!-- models/in_thousands/in_thousands.sql -->
{{ config(
    materialized='view',
    schema='analytics'
) }}

SELECT
  customer_tier,
  {{ numbers_in_thousands('lifetime_value', 3) }} as l_value_1000s
FROM
  {{ ref('order_summary') }}
```

---

---

## dbt docs

### Generating Documentations

dbt enables you to generate documentation for your project and data platform. Before generating documentation, add descriptions to your project resources. Add the `description` key to the same YAML files where you declare data tests. For example:

```yml
# models/order_summary/model_properties.yml
version: 2

models:
  # This corresponds to the order_summary.sql model
  - name: order_summary
    description: "Summary of customer orders with key metrics"
    # ...
    columns:
      - name: customer_id
        description: "Unique identifier for the customer"
        # ...
  # ...
```

Generate documentation for your project by following these steps:

1. Run the `dbt docs generate` command to compile relevant information about your dbt project and warehouse into `manifest.json` and `catalog.json` files, respectively.
2. Ensure you've created the models with `dbt run` or `dbt build` to view the documentation for all columns, not just those described in your project.
3. Run the `dbt docs serve` command if you're developing locally to use these `.json` files to populate a local website.

---

### Docs blocks

Docs blocks provide a robust method for documenting models and other resources using Jinja and markdown. Docs block files can contain arbitrary markdown, but they must be uniquely named.

To declare a docs block, use the Jinja `docs` tag. The name of a docs block can't start with a digit and may contain:

- Uppercase and lowercase letters (A-Z, a-z)
- Digits (0-9)
- Underscores (\_)

Docs blocks should be placed in files with a `.md` file extension. By default, dbt will search in all resource paths for docs blocks (for example, the combined list of `model-paths`, `seed-paths`, `analysis-paths`, `test-paths`, `macro-paths`, and `snapshot-paths`) — you can adjust this behavior using the `docs-paths` config.

Here is an example markdown file with docs blocks:

```md
<!-- models/order_summary/descriptions.md -->

{% docs doc_order_summary %}

# Order Summary Model

This model provides a high-level aggregation of customer behavior.

**Business Logic:**

- It calculates the total number of orders per customer.
- **Lifetime Value (LTV):** Calculated as the sum of all successful order totals minus returns.

**Usage Note:**
This table is used primarily by the Marketing team for segmentation and loyalty program analysis.
{% enddocs %}

{% docs doc_daily_orders %}

# Daily Orders Model

A time-series aggregation of sales performance.

**Key Metrics:**

- `total_revenue`: Sum of all orders placed on a specific calendar date.
- `revenue_category`: A categorical label based on the daily revenue threshold (High/Medium/Low).

**Warning:**
This model relies on the `raw_data.orders` source. If there is a delay in raw data ingestion, this table may be incomplete for the current date.
{% enddocs %}

{% docs doc_customer_id %}
The `customer_id` is the primary key from the source system. It must be unique across all customers and should never be null.
If you find duplicates here, please contact the Data Engineering team to check the upstream CRM sync.
{% enddocs %}
```

To use a docs block, reference it from your schema.yml file with the `doc()` function in place of a markdown string:

```yml
# models/order_summary/model_properties.yml
version: 2

models:
  - name: order_summary
    description: "{{ doc('doc_order_summary') }}" # <--- Changed here
    config:
      materialized: table
      tags: ["orders", "summary"]
      schema: "analytics"
    columns:
      - name: customer_id
        description: "{{ doc('doc_customer_id') }}" # <--- Changed here
        data_tests:
          - not_null
          - unique
          - relationships:
              to: source('raw_data', 'orders')
              field: customer_id
      - name: total_orders
        description: "Total number of orders placed by the customer"
        data_tests:
          - is_positive
      # ... rest of columns remain same

  - name: daily_orders
    description: "{{ doc('doc_daily_orders') }}" # <--- Changed here
    config:
      materialized: table
      tags: ["orders", "daily"]
      schema: "analytics"
    columns:
      - name: order_date
        description: "Date when the order was placed"
        data_tests:
          - not_null
      # ... rest of columns remain same
```

---

---

## Packages

dbt packages are standalone dbt projects, with models, macros, and other resources that tackle a specific problem area. As a dbt user, by adding a package to your project, all of the package's resources will become part of your own project. This means:

- Models in the package will be materialized when you `dbt run`.
- You can use `ref` in your own models to refer to models from the package.
- You can use `source` to refer to sources in the package.
- You can use macros in the package in your own project.

To add a package to our dbt project, we need to have `packages.yml` file in our project directory. This should be at the same level as your `dbt_project.yml` file. To install the package, we specify the package(s) we wish to add using one of the supported syntaxes. There are a few methods of specifying a package.

- [dbt hub](https://hub.getdbt.com/) is where we have various packages that people have built. To install a package from this hub, we specify the package like this:

```yml
# packages.yml
packages:
  - package: dbt-labs/snowplow
    version: 0.7.0
```

Hub packages require a version to be specified – you can find the latest release number on dbt Hub.

- Packages stored on a Git server can be installed using the git syntax. Add the Git URL for the package, and optionally specify a revision. The revision can be:

- a branch name
- a tagged release
- a specific commit (full 40-character hash)

For example,

```yml
# packages.yml
packages:
  - git: "https://github.com/dbt-labs/dbt-utils.git" # git URL
    revision: 0.9.2 # tag or branch name

  - local: /opt/dbt/redshift
```

- A "local" package is a dbt project accessible from your local file system. You can install local packages by specifying the project's path. It works best when you nest the project within a subdirectory relative to your current project's directory.

```yml
# packages.yml
packages:
  - local: relative/path/to/subdirectory
```

When we run `dbt deps` we complete installing the package(s). Packages get installed in the `dbt_packages` directory. This could be changed by changing the value for `packages-install-path` in the `dbt_project.yml` file. Also, by default this directory is ignored by git, to avoid duplicating the source code for the package.

When you update a version or revision in your `packages.yml` file, it isn't automatically updated in your dbt project. You should run `dbt deps` to update the package. You may also need to run a full refresh of the models in this package.

When you remove a package from your `packages.yml` file, it isn't automatically deleted from your dbt project, as it still exists in your `dbt_packages/` directory. If you want to completely uninstall a package, you should either:

- delete the package directory in `dbt_packages/`; or
- run `dbt clean` to delete all packages (and any compiled models), followed by `dbt deps`.

---

---

## Hooks

Hooks are snippets of SQL that are executed at different times:

- `pre-hook`: executed before a model, seed or snapshot is built.
- `post-hook`: executed after a model, seed or snapshot is built.
- `on-run-start`: executed at the start of
  - `dbt build`, `dbt compile`, `dbt docs generate`, `dbt run`, `dbt seed`, `dbt snapshot`, or `dbt test`.
- `on-run-end`: executed at the end of
  - `dbt build`, `dbt compile`, `dbt docs generate`, `dbt run`, `dbt seed`, `dbt snapshot`, or `dbt test`.

We can define hooks in the `dbt_project.yml` file, the model SQL file, and properties yaml files. If you define hooks in both your `dbt_project.yml` and in the config block of a model, both sets of hooks will be applied to your model.

Here is a syntax for model hooks:

```yml
# dbt_project.yml
models:
  <resource-path>:
    +pre-hook: SQL-statement | [SQL-statement]
    +post-hook: SQL-statement | [SQL-statement]
```

```sql
{{ config(
    pre_hook="SQL-statement" | ["SQL-statement"],
    post_hook="SQL-statement" | ["SQL-statement"],
) }}

select ...
```

```yml
# models/properties.yml
models:
  - name: [<model_name>]
    config:
      pre_hook: <sql-statement> | [<sql-statement>]
      post_hook: <sql-statement> | [<sql-statement>]
```

In these examples, we use the `|` symbol to separate two different formatting options for SQL statements in pre-hooks and post-hooks. The first option (without brackets) accepts a single SQL statement as a string, while the second (with brackets) accepts multiple SQL statements as an array of strings. Replace `SQL-STATEMENT` with your SQL.

Here is a syntax for seed hooks:

```yml
# dbt_project.yml
seeds:
  <resource-path>:
    +pre-hook: SQL-statement | [SQL-statement]
    +post-hook: SQL-statement | [SQL-statement]
```

```yml
# seeds/properties.yml
seeds:
  - name: [<seed_name>]
    config:
      pre_hook: <sql-statement> | [<sql-statement>]
      post_hook: <sql-statement> | [<sql-statement>]
```

Here is a syntax for snapshot hooks:

```yml
# dbt_project.yml
snapshots:
  <resource-path>:
    +pre-hook: SQL-statement | [SQL-statement]
    +post-hook: SQL-statement | [SQL-statement]
```

```yml
# snapshots/snapshot.yml
snapshots:
  - name: [<snapshot_name>]
    config:
      pre_hook: <sql-statement> | [<sql-statement>]
      post_hook: <sql-statement> | [<sql-statement>]
```

Below example uses `dbt_project.yml`, `model_properties.yml`, and the config block in the `order_summary.sql` file:

```yml
# dbt_project.yml
# ...
models:
  demodbt_33:
    +post-hook: "INSERT INTO dbt_log (message) VALUES ('Finished building {{ this }}')"
    # ...

on-run-start:
  # 1. Clean up old log table (Using IF EXISTS so it doesn't error on first run)
  - "DROP TABLE IF EXISTS dbt_log"

  # 2. Create a fresh log table for this session
  - "CREATE TABLE dbt_log (message TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"

  # 3. Log that the run has started
  - "INSERT INTO dbt_log (message) VALUES ('--- Start of Run ---')"

on-run-end:
  - "INSERT INTO dbt_log (message) VALUES ('--- End of Run ---')"
```

```yml
# models/order_summary/model_properties.yml
version: 2

models:
  # ...
  - name: daily_orders
    description: "{{ doc('doc_daily_orders') }}"
    config:
      materialized: table
      tags: ["orders", "daily"]
      schema: "analytics"
      pre-hook: "INSERT INTO dbt_log (message) VALUES ('Pre-hook: Building daily_orders')"
    columns:
      # ...
```

```jinja
-- models/order_summary/order_summary.sql
{{ config(
    materialized='table',
    post_hook="INSERT INTO dbt_log (message) VALUES ('Post-hook: order_summary is done')"
    ) }}

WITH order_data as (
  <!-- ... -->
```

---

---
