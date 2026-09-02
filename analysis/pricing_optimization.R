# ================================
# Mobile Feast – Question 3: Revenue Strategy Optimization
# Beginner-friendly, step-by-step script
# ================================

# ---- 0) How to use this script (read me first) ----
# 1. Open RStudio.
# 2. Go to: File -> New Project -> Existing Directory -> Browse to the folder "mobilefeast-student/mobilefeast-student".
# 3. In the RStudio Files pane, open this file: code/q3_revenue_strategy.R
# 4. Place your cursor anywhere and press Ctrl+Shift+Enter (Windows) or Cmd+Shift+Enter (Mac) to run the whole script
#    OR run line by line with Ctrl+Enter / Cmd+Enter.
# 5. All outputs (plots/tables) will be saved to the 'outputs' folder.

# ---- 1) Packages ----
if (!require("tidyverse")) install.packages("tidyverse"); library(tidyverse)
if (!require("broom")) install.packages("broom"); library(broom)
if (!require("patchwork")) install.packages("patchwork"); library(patchwork)
if (!require("scales")) install.packages("scales"); library(scales)

theme_set(theme_minimal())

# ---- 2) Load data ----
raw <- readr::read_csv("data/mobile_feast_operations.csv", show_col_types = FALSE)

# Quick inspection
glimpse(raw)
summary(raw)

# ---- 3) Clean & feature engineer ----
df <- raw |>
  mutate(
    Date = as.Date(Date),
    City = factor(City),
    Festival = factor(Festival, levels = c(0,1), labels = c("No", "Yes")),
    revenue = Price * `Quantity Sold`,
    # Derived features
    dow = weekdays(Date),
    weekend = if_else(dow %in% c("Saturday","Sunday"), "Weekend", "Weekday")
  )

# Sanity checks
stopifnot(all(df$Price >= 6 & df$Price <= 10))

# ---- 4) Exploratory visuals (saved to results/) ----
# Quantity vs Price with smooth
p_q_p <- ggplot(df, aes(x = Price, y = `Quantity Sold`)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "loess", se = TRUE) +
  labs(title = "Demand scatter: Quantity vs Price", x = "Price ($)", y = "Quantity Sold")
ggsave("results/q_vs_price.png", p_q_p, width = 7, height = 5, dpi = 200)

# Revenue vs Price (empirical)
p_rev <- df |>
  group_by(Price) |>
  summarize(mean_qty = mean(`Quantity Sold`), .groups = "drop") |>
  mutate(mean_revenue = Price * mean_qty) |>
  ggplot(aes(x = Price, y = mean_revenue)) +
  geom_line() + geom_point() +
  labs(title = "Average Revenue by Price (empirical)", x = "Price ($)", y = "Revenue ($)")
ggsave("results/revenue_curve_empirical.png", p_rev, width = 7, height = 5, dpi = 200)

# Facet by City and Festival
p_facets <- ggplot(df, aes(x = Price, y = `Quantity Sold`)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "loess", se = FALSE) +
  facet_grid(Festival ~ City) +
  labs(title = "Demand by City × Festival", x = "Price ($)", y = "Quantity Sold")
ggsave("results/demand_facets_city_festival.png", p_facets, width = 9, height = 6, dpi = 200)

# ---- 5) Model demand to estimate elasticity ----
# Log-linear demand with controls and city FE
# log(Q) = a + b*log(P) + c1*Temp + c2*Precip + d*Festival + City FE + e
df <- df |>
  mutate(
    log_qty = log(`Quantity Sold` + 1e-6),   # small epsilon to avoid log(0)
    log_price = log(Price)
  )

m1 <- lm(log_qty ~ log_price + Temperature + `Probability of Precipitation` + Festival + City, data = df)
summary(m1)

# Elasticity is b_hat on log_price
elasticity <- coef(m1)["log_price"]
message(sprintf("Estimated price elasticity of demand (overall): %.3f", elasticity))

# Save regression table
reg_tbl <- broom::tidy(m1) |>
  mutate(term = as.character(term))
readr::write_csv(reg_tbl, "results/regression_q3_loglin.csv")

# ---- 6) Optimize revenue over a price grid ----
# We predict quantity at candidate prices 6..10 holding other covariates at typical levels
price_grid <- tibble(Price = seq(6, 10, by = 0.10))
typical <- df |>
  summarize(
    Temperature = median(Temperature, na.rm = TRUE),
    `Probability of Precipitation` = median(`Probability of Precipitation`, na.rm = TRUE)
  )

cities <- distinct(df, City) |> pull(City)
festivals <- c("No","Yes")

predict_grid <- expand_grid(
  price_grid,
  City = cities,
  Festival = factor(festivals, levels = c("No","Yes"))
) |>
  crossing(typical) |>
  mutate(
    log_price = log(Price)
  )

pred_logq <- predict(m1, newdata = predict_grid)
predict_grid <- predict_grid |>
  mutate(
    qty_hat = exp(pred_logq),   # inverse log; for teaching we skip smearing adjustment
    revenue_hat = Price * qty_hat
  )

# Find argmax price for each City × Festival
opt_tbl <- predict_grid |>
  group_by(City, Festival) |>
  slice_max(revenue_hat, n = 1, with_ties = FALSE) |>
  ungroup() |>
  arrange(City, Festival) |>
  mutate(
    price_opt = round(Price, 2),
    qty_opt = round(qty_hat, 1),
    revenue_opt = round(revenue_hat, 2)
  ) |>
  select(City, Festival, price_opt, qty_opt, revenue_opt)

readr::write_csv(opt_tbl, "results/q3_optimal_prices_by_city_festival.csv")

# Plot revenue curves by City × Festival
p_rev_cf <- predict_grid |>
  ggplot(aes(x = Price, y = revenue_hat)) +
  geom_line() +
  facet_grid(Festival ~ City) +
  labs(title = "Predicted Revenue vs Price by City × Festival (log-linear model)",
       x = "Price ($)", y = "Predicted Revenue ($)")
ggsave("results/revenue_curves_city_festival.png", p_rev_cf, width = 9, height = 6, dpi = 200)

# ---- 7) Executive summary style table ----
opt_tbl |>
  mutate(across(c(price_opt, revenue_opt), ~ scales::dollar(.))) |>
  readr::write_csv("results/q3_optimal_prices_by_city_festival_pretty.csv")

# ---- 8) Optional: Robustness with quadratic demand (levels) ----
# Quantity = a + b*Price + c*Price^2 + controls + FE
m2 <- lm(`Quantity Sold` ~ Price + I(Price^2) + Temperature + `Probability of Precipitation` + Festival + City, data = df)
summary(m2)
readr::write_csv(broom::tidy(m2), "results/regression_q3_quad.csv")

# Predict and compare revenue shape
predict_grid2 <- predict_grid |>
  select(-log_price) |>
  mutate(q_hat2 = pmax(0, predict(m2, newdata = predict_grid))) |>
  mutate(revenue_hat2 = Price * q_hat2)

p_rev_cf2 <- predict_grid2 |>
  ggplot(aes(x = Price, y = revenue_hat2)) +
  geom_line() +
  facet_grid(Festival ~ City) +
  labs(title = "Predicted Revenue vs Price by City × Festival (quadratic model)",
       x = "Price ($)", y = "Predicted Revenue ($)")
ggsave("results/revenue_curves_city_festival_quadratic.png", p_rev_cf2, width = 9, height = 6, dpi = 200)

# Save optimal prices under quadratic model
opt_tbl2 <- predict_grid2 |>
  group_by(City, Festival) |>
  slice_max(revenue_hat2, n = 1, with_ties = FALSE) |>
  ungroup() |>
  transmute(City, Festival, price_opt_quad = round(Price,2),
            qty_opt_quad = round(q_hat2,1), revenue_opt_quad = round(revenue_hat2,2))

readr::write_csv(opt_tbl2, "results/q3_optimal_prices_by_city_festival_quadratic.csv")

# ---- 9) Save a combined plot (empirical vs model) ----
combined <- p_rev / p_q_p
ggsave("results/q3_empirical_vs_demand.png", combined, width = 9, height = 9, dpi = 200)

# ---- 10) Print key outputs to console ----
print(opt_tbl)
print(opt_tbl2)
message("Artifacts written to the 'outputs' folder.")
