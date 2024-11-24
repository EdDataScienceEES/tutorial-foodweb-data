# Visualising Food Webs on R
# Your name
# DD/MM/YYYY
# -------------------------------------

# 1a.	Download data from cheddar

# Install arequired packages (omit if you already have them installed)
install.packages("cheddar") # data and functions for analysing/visualising food web data
install.packages("tidyverse") # includes data wrangling tools such as dplyr, tidyr
install.packages("ggplot2") # a useful graphic display tool
install.packages("igraph") # helps visualise food web network
install.packages("ggraph") # an extension of ggplot2, creates food web heat map
install.packages("plotly") # Allows plots to get interactive

# Load required libraries
library(cheddar)
library(tidyverse) 
library(ggplot2)
library(igraph) 
library(ggraph)
library(plotly)

# Obtain the BroadstoneStream dataset from cheddar and save the useful data frames as objects
data("BroadstoneStream")
node_properties <- NPS(BroadstoneStream) # Extract node properties (species data)
trophic_links <- TLPS(BroadstoneStream) # Extract trophic links (prey-predator interactions)
properties <- BroadstoneStream[["properties"]] # Extract properties (unit key)

# ALTERNATIVE: To directly access data without cheddar, instead of ("BroadstoneStream"), use the below code:
node_properties <- read.csv("broadstonestream_data/nodes.csv")   # Extract node properties (species data)
trophic_links <- read.csv("broadstonestream_data/trophic_links.csv")  # Extract trophic links (prey-predator interactions)
properties <- read.csv("broadstonestream_data/properties.csv")  # Extract properties (unit key)

# Examine data properties
str(properties)
str(node_properties)
str(trophic_links)

# -------------------------------------

# 1b.	Subset, extract and modify data using dplyr 

# Let's view what species do we have exactly!
unique(node_properties$node) 
# There are some producers and bacteria here! I would assume they are resources.
# See if they are in resources
unique(trophic_links$resource)

# They don't seem to be! If we run another line to find differences...
nodes_not_in_resources <- setdiff(unique(node_properties$node), unique(trophic_links$resource))
resources_not_in_nodes <- setdiff(unique(trophic_links$resource), unique(node_properties$node))
# And display the result...
list(Nodes_Not_in_Resources = nodes_not_in_resources,
  Resources_Not_in_Nodes = resources_not_in_nodes)

# Calculate biomass (M * N) for prey and keep only mass for predators
node_properties <- node_properties %>%
  mutate(
    prey_biomass = M * N,  # Prey biomass includes mass and density
    predator_mass = M      # Predator biomass is just the mass
  ) %>%
  select(node, prey_biomass, predator_mass)  # Keep only necessary columns

# Joining trophic_links with node_properties
trophic_links <- trophic_links %>%
  # Add prey biomass by joining on 'resource' (prey nodes)
  left_join(node_properties %>% select(node, prey_biomass), by = c("resource" = "node")) %>%
  # Add predator mass by joining on 'consumer' (predator nodes)
  left_join(node_properties %>% select(node, predator_mass), by = c("consumer" = "node"))

# Calculate and normalise interaction strength
food_web <- trophic_links %>% # Rename the data frame as it not only contains trophic links now
  group_by(consumer) %>%  # Normalised strengths are based on single predator 
  mutate(
    # Calculate interaction strength (I)
    interaction_strength = prey_biomass / predator_mass,  
    # Normalize interaction strength 
    normalized_strength = interaction_strength / sum(interaction_strength, na.rm = TRUE)
  ) %>%
  ungroup()  # Ungroup after calculations to avoid accidental grouping later 

# -------------------------------------

# 2a.	Visualize data as food web network with ggraph 

# Convert our food_web data frame to an igraph object
food_web_plot <- graph_from_data_frame(food_web, directed = TRUE)

# OPTIONAL: View what igraph didto our data!
str(food_web_plot)

# Coding for a food web network and save it as an object
food_web_network <- ggraph(food_web_plot) +  # Calls for a plot using package ggraph
  geom_node_point() +  # Add a layer to plot our nodes as points 
  geom_edge_link(aes(alpha = normalized_strength)) +  # Add another layer to plot our links based on normalised_strength
  geom_node_text(aes(label = name), repel = TRUE, size = 4)   # Lastly, label our nodes!

# View our plot 
print(food_web_network)

# Use ggraph to visualize the food web again, but make it prettier
food_web_network <- ggraph(food_web_plot, layout = 'fr') +  # Fruchterman-Reingold layout tends to cluster interacting species together
  geom_edge_link(
    aes(color = normalized_strength), # Plot edges (links) and colour them based on normalized strength
    arrow = arrow(length = unit(5, "mm"), type = "closed")  # Add arrowheads to show who's predator who's prey
  ) +  
  scale_edge_color_gradient(low = "green", high = "red", name = "Normalized Interaction Strength") +  # Customise normalized strength gradient 
  geom_node_label(
    aes(label = name), # Instead of adding node circle and labelling text separately, add nodes as rectangular labels directly
    fill = "white", # Customise box colour to white
    color = "black", # Customise text colour to black
    size = 2.5,  # Customise text size
    label.size = 0.25 # Customise the label's border size
  ) +  
  theme_void() +  # Removes the grey panel in the background
  labs(title = "Broadstone Stream Food Web")+  # Add title
  theme(plot.title = element_text(hjust = 0.5))  # Center the title

# View the plot 
print(food_web_network)

# Save as a png (for a clearer view)
ggsave("food_web_plot.jpg", plot = food_web_network, width = 15, height = 15, dpi = 300)

# -------------------------------------

# 2b.	Visualize biomass flow as heatmap with ggplot2

# Build a biomass flow heatmap (predator on horizontal axis, prey on vertical axis, colour represents normalized interaction strength)
heatmap_plot <- ggplot(food_web, aes(x = consumer, y = resource, fill = normalized_strength)) +
  geom_tile() + # Add a tile plot layer as the heatmap
  labs( # Add the title and labels
    title = "Food Web Heatmap of Interaction Strength",
    x = "Predator", 
    y = "Prey") 

# Let's take a look at the heatmap
print(heatmap_plot)

# Improve the heatmap
heatmap_plot <- ggplot(food_web, aes(x = consumer, y = resource, fill = normalized_strength)) +
  geom_tile(color = "#4d4d4d", size = 0.2) + # Colour the border so we can easily count the number of tiles
  scale_fill_gradient(low = "green", high = "red",# Change to a more distinctive colour gradient
                      name = "Normalized Interaction Strength")+  # Set the legend title here
  theme_minimal() + # choose a 
  labs(title = "Food Web Heatmap of Interaction Strength", # Add the title and labels
       x = "Predator", y = "Prey") +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1), # Rotate labels such that they don't overlap on the x-axis
    title = element_text(hjust = 0.5), # Centre the title
    panel.grid = element_blank(), # Removes confusing grid
  ) 

# View the heatmap
print(heatmap_plot)

# -------------------------------------

# 2c.	Make the heatmap interactive with plotly

# Convert the ggplot heatmap to an interactive plotly plot
interactive_heatmap <- ggplotly(heatmap_plot) 

# Display the interactive plot
interactive_heatmap

# -------------------------------------

# 3a.	Preparing a Function for Species Removal Simulations

# Define the species to remove 
target_species <- "Cordulegaster boltonii"

# Optional: View species names
species_list <- V(food_web_plot)$name
print(species_list)

# Define function
calculate_trophic_isolations <- function(food_web_plot, target_species) {
  # Remove the target species
  new_network <- delete_vertices(food_web_plot, target_species)
  
  # Identify species that are disconnected and thus 'isolated'
  isolated_species <- V(new_network)$name[degree(new_network, mode = "all") == 0]
  
  # Return the number of trophic isolations and species names
  tibble(
    removed_species = unlist(target_species),  # Using list to keep species name(s) in a list format
    isolated_species = unlist(isolated_species),  # Store isolated species names
    trophic_isolations = length(isolated_species),
    remaining_species = vcount(new_network)
  )
}

# -------------------------------------

# 3b.	Simulation of species removal to measure ecosystem impacts

# Call the function now and save results as a new object
results <- calculate_trophic_isolations(food_web_plot, target_species)
print(results)

# -------------------------------------

# 3c.	Evaluation of keystone species hypothesis using statistical analyses

# Generate null distribution…
# We want 1000 random trials
null_distribution <- replicate(1000, { 
  # Randomly select 1 species only for each trial
  random_species <- sample(V(food_web_plot)$name, 1)
  # Calculate trophic isolation for the random species
  calculate_trophic_isolations(food_web_plot, random_species)$trophic_isolations
})

# Calculate the p-value
# Number of trophic isolations first
observed_isolations <- results$trophic_isolations[[1]]
null_distribution <- unlist(null_distribution)

p_value <- mean(null_distribution >= observed_isolations)

# Print the p-value
cat("P-value for the permutation test: ", p_value, "\n")
