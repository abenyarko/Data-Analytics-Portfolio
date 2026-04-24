# ============================================================
# Retail Sales Exploratory Data Analysis
# ============================================================
# Author : Data Analytics Portfolio
# Description: EDA of retail transaction data to uncover
#              sales patterns, seasonality, and top performers.
# ============================================================

library(tidyverse)
library(lubridate)
library(scales)
library(ggthemes)

# ── 1. Load Data ─────────────────────────────────────────────
sales <- read_csv("data/retail_sales.csv",
                  col_types = cols(
                    OrderID    = col_character(),
                    OrderDate  = col_date(format = "%Y-%m-%d"),
                    Region     = col_character(),
                    SalesRep   = col_character(),
                    Category   = col_character(),
                    SubCategory = col_character(),
                    Product    = col_character(),
                    Quantity   = col_double(),
                    UnitPrice  = col_double(),
                    UnitCost   = col_double()
                  ))

# ── 2. Feature Engineering ───────────────────────────────────
sales <- sales %>%
  mutate(
    Revenue  = Quantity * UnitPrice,
    Profit   = Quantity * (UnitPrice - UnitCost),
    Margin   = Profit / Revenue,
    Year     = year(OrderDate),
    Month    = month(OrderDate, label = TRUE, abbr = TRUE),
    Quarter  = paste0("Q", quarter(OrderDate)),
    Weekday  = wday(OrderDate, label = TRUE, abbr = TRUE)
  )

# ── 3. Summary Statistics ────────────────────────────────────
cat("\n===== Overall Summary =====\n")
cat(sprintf("Total Orders   : %d\n", nrow(sales)))
cat(sprintf("Total Revenue  : %s\n", dollar(sum(sales$Revenue))))
cat(sprintf("Total Profit   : %s\n", dollar(sum(sales$Profit))))
cat(sprintf("Overall Margin : %.1f%%\n", mean(sales$Margin) * 100))
cat(sprintf("Date Range     : %s  to  %s\n",
            min(sales$OrderDate), max(sales$OrderDate)))

# Revenue by Category
cat("\n===== Revenue by Category =====\n")
sales %>%
  group_by(Category) %>%
  summarise(
    Orders  = n(),
    Revenue = sum(Revenue),
    Profit  = sum(Profit),
    Margin  = percent(Profit / Revenue, accuracy = 0.1)
  ) %>%
  arrange(desc(Revenue)) %>%
  print(n = Inf)

# ── 4. Monthly Revenue Trend ─────────────────────────────────
monthly <- sales %>%
  mutate(YearMonth = floor_date(OrderDate, "month")) %>%
  group_by(YearMonth) %>%
  summarise(Revenue = sum(Revenue), Profit = sum(Profit))

p1 <- ggplot(monthly, aes(x = YearMonth)) +
  geom_line(aes(y = Revenue, colour = "Revenue"), linewidth = 1) +
  geom_line(aes(y = Profit,  colour = "Profit"),  linewidth = 1, linetype = "dashed") +
  geom_area(aes(y = Revenue), fill = "#4e79a7", alpha = 0.1) +
  scale_y_continuous(labels = dollar_format(prefix = "$")) +
  scale_colour_manual(values = c("Revenue" = "#4e79a7", "Profit" = "#f28e2b")) +
  labs(title    = "Monthly Revenue & Profit Trend",
       subtitle = "Dashed line = Profit  |  Shaded area = Revenue",
       x        = NULL,
       y        = "Amount (USD)",
       colour   = NULL) +
  theme_clean() +
  theme(legend.position = "top")

print(p1)

# ── 5. Revenue by Region ─────────────────────────────────────
by_region <- sales %>%
  group_by(Region) %>%
  summarise(Revenue = sum(Revenue), Profit = sum(Profit)) %>%
  arrange(desc(Revenue))

p2 <- ggplot(by_region, aes(x = reorder(Region, Revenue), y = Revenue, fill = Region)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = dollar(Revenue, scale = 1e-3, suffix = "K")),
            hjust = -0.1, size = 3.5) +
  coord_flip() +
  scale_y_continuous(labels = dollar_format(prefix = "$"), expand = expansion(mult = c(0, 0.15))) +
  scale_fill_tableau() +
  labs(title = "Total Revenue by Region",
       x     = NULL,
       y     = "Revenue (USD)") +
  theme_clean()

print(p2)

# ── 6. Top 10 Products by Revenue ───────────────────────────
top_products <- sales %>%
  group_by(Product, Category) %>%
  summarise(Revenue = sum(Revenue), .groups = "drop") %>%
  slice_max(Revenue, n = 10)

p3 <- ggplot(top_products, aes(x = reorder(Product, Revenue), y = Revenue, fill = Category)) +
  geom_col() +
  geom_text(aes(label = dollar(Revenue, scale = 1e-3, suffix = "K")),
            hjust = -0.1, size = 3) +
  coord_flip() +
  scale_y_continuous(labels = dollar_format(prefix = "$"), expand = expansion(mult = c(0, 0.2))) +
  scale_fill_tableau() +
  labs(title = "Top 10 Products by Revenue",
       x     = NULL,
       y     = "Revenue (USD)",
       fill  = "Category") +
  theme_clean() +
  theme(legend.position = "bottom")

print(p3)

# ── 7. Revenue by Weekday ────────────────────────────────────
by_weekday <- sales %>%
  group_by(Weekday) %>%
  summarise(Revenue = sum(Revenue), Orders = n())

p4 <- ggplot(by_weekday, aes(x = Weekday, y = Revenue, fill = Weekday)) +
  geom_col(show.legend = FALSE) +
  scale_y_continuous(labels = dollar_format(prefix = "$")) +
  scale_fill_tableau() +
  labs(title = "Revenue Distribution by Day of Week",
       x     = "Day of Week",
       y     = "Revenue (USD)") +
  theme_clean()

print(p4)

# ── 8. Category Revenue Share (Quarterly) ───────────────────
quarterly_cat <- sales %>%
  group_by(Quarter, Category) %>%
  summarise(Revenue = sum(Revenue), .groups = "drop")

p5 <- ggplot(quarterly_cat, aes(x = Quarter, y = Revenue, fill = Category)) +
  geom_col(position = "fill") +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_tableau() +
  labs(title = "Category Revenue Share by Quarter",
       x     = "Quarter",
       y     = "Revenue Share",
       fill  = "Category") +
  theme_clean() +
  theme(legend.position = "right")

print(p5)

# ── 9. Profit Margin Distribution ───────────────────────────
p6 <- ggplot(sales, aes(x = Margin, fill = Category)) +
  geom_histogram(binwidth = 0.02, colour = "white", alpha = 0.8) +
  facet_wrap(~Category, scales = "free_y") +
  scale_x_continuous(labels = percent_format()) +
  scale_fill_tableau() +
  labs(title = "Profit Margin Distribution by Category",
       x     = "Profit Margin",
       y     = "Number of Orders") +
  theme_clean() +
  theme(legend.position = "none")

print(p6)

# ── 10. Sub-category Heatmap (Revenue) ──────────────────────
subcat_heatmap <- sales %>%
  group_by(Category, SubCategory) %>%
  summarise(Revenue = sum(Revenue), .groups = "drop")

p7 <- ggplot(subcat_heatmap, aes(x = Category, y = SubCategory, fill = Revenue)) +
  geom_tile(colour = "white", linewidth = 0.5) +
  geom_text(aes(label = dollar(Revenue, scale = 1e-3, suffix = "K")), size = 3) +
  scale_fill_gradient(low = "#eef3fb", high = "#2166ac", labels = dollar_format(scale = 1e-3, suffix = "K")) +
  labs(title = "Revenue Heatmap: Category × Sub-category",
       x     = "Category",
       y     = "Sub-category",
       fill  = "Revenue (USD)") +
  theme_clean() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

print(p7)

cat("\n✅ EDA complete. All plots rendered.\n")
