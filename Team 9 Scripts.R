library(dplyr)
library(ggplot2)
library("data.table")
library(lubridate)
library(tidyverse)
library(magrittr)
library(gridExtra)

# Loading data

df <- fread("C:\\Users\\Pacifique Iradukunda\\Downloads\\reviews_clean.csv", header=TRUE, sep=",")

data_file_q5 <- "C:\\Users\\Pacifique Iradukunda\\Downloads\\question_5.csv"

data_file_q6 <- "C:\\Users\\Pacifique Iradukunda\\Downloads\\question_6.csv"

df_reviews_q5 <- read_csv(data_file_q5)
df_reviews_q6 <- read_csv(data_file_q6)

df$review_date <- as.Date(df$review_date)

# Question 5

df_reviews_q5$verified_purchase <- factor(df_reviews_q5$verified_purchase, levels = c(0, 1), labels = c("Not Verified", "Verified"))

# create a ggplot using the df_reviews_q5
# verified purchase status as the x axis, mean star rating as the y axis

ggplot(df_reviews_q5, aes(x = verified_purchase, y = star_rating, fill = verified_purchase)) + # set x and y axis, and align bar color with verified status
  geom_bar(stat = "summary", fun = "mean") + # use mean as summary statistic
  labs(x = "Verified Purchase", y = "Average Star Rating") + # add labels
  theme_minimal() + # use minimal theme to make things less visually busy
  coord_cartesian(ylim = c(0,5)) # set the legend of the y axis to 0-5

# Question 6

ggplot(df_reviews_q6, aes(x = star_rating)) +   
  geom_histogram(binwidth = 1) +
  labs(x = "Star Rating", y = "Frequency", title = "Distribution of Star Ratings") +  # labels and title
  theme_minimal()  # visually clean
  coord_cartesian(ylim = c(0,5000000)) # set y limit to 5,000,000
  

# Question 7  
#Analyzing Average Character Length by Star Rating

average_chars_by_rating <- aggregate(nchar(review_body) ~ star_rating, data = df, FUN = mean)

colnames(average_chars_by_rating)[2] <- "avg_char_length"

ggplot(average_chars_by_rating, aes(x = star_rating, y = avg_char_length)) +
  geom_bar(stat = "identity", fill = "lightblue") +
  labs(title = "Average Character Length by Star Rating",
       x = "Star Rating",
       y = "Average Character Length") +
  theme_minimal()

#Analyzing number of star ratings in each rating group

ggplot(df, aes(x = factor(star_rating), fill = factor(star_rating))) +
  geom_bar() +
  labs(title = "Histogram of Star Ratings",
       x = "Star Rating",
       y = "Frequency") +
  scale_x_discrete(labels = c("1", "2", "3", "4", "5")) +
  scale_fill_discrete(name = "Star Rating") +
  theme_minimal()


# Compute the number of characters in each review body
df$char_count <- nchar(as.character(df$review_body))

# Plot the histogram using ggplot2
ggplot(df, aes(x=char_count)) +
  geom_histogram(binwidth=10, fill="blue", color="black", alpha=0.7) +
  labs(title="Distribution of Review Body Length",
       x="Number of Characters", y="Frequency of Reviews") +
  theme_minimal()

mean_char_count <- mean(df$char_count, na.rm = TRUE)
median_char_count <- median(df$char_count, na.rm = TRUE)
sd_char_count <- sd(df$char_count, na.rm = TRUE)
mad_val <- mad(df$char_count, na.rm = TRUE)
unusual_values <- df$char_count[abs(df$char_count - median_char_count) > 2.5 * mad_val]

# Plot the histogram with vertical lines for mean and median
ggplot(df, aes(x=char_count)) +
  geom_histogram(binwidth=10, fill="blue", color="black", alpha=0.7) +
  geom_vline(aes(xintercept=mean_char_count), color="red", linetype="dashed", size=0.8) +
  geom_vline(aes(xintercept=median_char_count), color="green", linetype="dashed", size=0.8) +
  labs(title="Distribution of Review Body Length",
       x="Number of Characters", y="Frequency of Reviews",
       subtitle=paste("Mean:", round(mean_char_count, 2), "Median:", round(median_char_count, 2), "Std Dev:", round(sd_char_count, 2))) +
  theme_minimal()

print(na.omit(unusual_values))

filtered_resized_df <- df %>%
  filter(helpful_votes >= 1)

#Question 8

df_q8 <- df %>%
  mutate(year = year(review_date), 
         month = month(review_date, label = TRUE))

# Aggregate data by year and month
monthly_counts <- df_q8 %>%
  group_by(year, month) %>%
  summarize(count = n())

# Plot data with a grid of plots for each year
plot_obj <- ggplot(monthly_counts, aes(x=month, y=count)) +
  geom_col(fill="skyblue") +
  labs(x="Month", y="Number of Reviews", title = "Monthly Reviews for Evey Year") +
  facet_wrap(~year, scales="free_y", ncol=3) +  # facet_wrap creates the grid layout
  theme_bw() +
  theme(strip.background = element_rect(fill="skyblue"),  # Making the year label background skyblue
        strip.text = element_text(size=12, color="white"))  # Adjusting the year label text

# Display the plot
print(plot_obj)

# Save the plot
ggsave(filename = "all_years_plot.png", plot = plot_obj, 
       width = 14,   # Adjust width as needed
       height = 10,  # Adjust height as needed
       dpi = 300     # Set dpi to 300 for high resolution
)

#Question 9

result_year <- filtered_resized_df %>%
  group_by(Year = format(review_date, "%Y")) %>%
  summarize(n = n())

#View(result_year)

ggplot(result_year, aes(x = Year, y = n, group = 1)) +  # Add group = 1 inside aes
  labs(x="Year", y="Number of Helpful Reviews", title = "Yearly Reviews") +
  geom_line() + 
  theme(axis.text.x = element_text(angle = 0))

# Question 10

count_per_group <- df %>%
  group_by(Year = format(review_date, "%Y")) %>%
  summarize(count_in_df = n())

count_in_filtered <- filtered_resized_df %>%
  group_by(Year = format(review_date, "%Y")) %>%
  summarize(count_in_filtered = n())

result_year_new <- count_per_group %>%
  left_join(count_in_filtered, by = "Year")

result_year_new$index <- result_year_new$count_in_filtered / result_year_new$count_in_df

ggplot(result_year_new, aes(x = Year, y = index)) +
  geom_point() + 
  theme(axis.text.x = element_text(angle = 30))

ggplot(result_year_new, aes(x = Year, y = index, group = 1)) +  # Add group = 1 inside aes
  labs(x="Year", y="Index", title = "Index Plot") +
  geom_line() + 
  theme(axis.text.x = element_text(angle = 0))

#Question 11

df$helpfulness_ratio <- df$helpful_votes / df$total_votes

# Average helpfulness ratio and star rating for Vine vs Non-Vine
avg_metrics <- df %>%
  group_by(vine) %>%
  summarise(avg_ratio = mean(helpfulness_ratio, na.rm=TRUE),
            avg_star_rating = mean(star_rating, na.rm=TRUE))

# Visualization: Average Helpfulness Ratio
ggplot(avg_metrics, aes(x=factor(vine), y=avg_ratio, fill=factor(vine))) +
  geom_bar(stat="identity") +
  labs(title="Average Helpfulness Ratio: Vine vs. Non-Vine", 
       x="Vine Review", 
       y="Average Helpfulness Ratio") +
  theme_minimal()

# Visualization: Average Star Rating
ggplot(avg_metrics, aes(x=factor(vine), y=avg_star_rating, fill=factor(vine))) +
  geom_bar(stat="identity") +
  labs(title="Average Star Rating: Vine vs. Non-Vine", 
       x="Vine Review", 
       y="Average Star Rating") +
  theme_minimal()
