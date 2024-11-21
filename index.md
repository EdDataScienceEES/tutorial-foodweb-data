<center><img src="{{ site.baseurl }}/tutheaderbl.png" alt="Img"></center>

To add images, replace `tutheaderbl1.png` with the file name of any image you upload to your GitHub repository.

### Tutorial Aims

#### <a href="#section1"> 1. Extract ecological data from external library `cheddar`</a>

#### <a href="#section2"> 2. Tidy and calculate ecological data useful for food webs</a>

#### <a href="#section3"> 3. Visualise feeding relations of a food web using `igraph` and `ggraph` package </a>

#### <a href="#section4"> 4. Visualise biomass flow of a food web using `ggplot2`</a>


### Key Steps you will go through in this tutorial:

1.	Download data from `cheddar`

2.	Subset, extract and modify data using `dplyr`

  a.	Combining node and trophic link data from cheddar into long format table
  
  b.	Calculating biomass flow and interaction strength
  
3.	Visualise feeding relations of a food web using  `ggraph`  package

4.	Visualise data as heatmap in `ggplot2`

  a.	Using `geom_tile` as a template
  
  b.	Make the heatmap interactive with `plotly`

---------------------------

Species interactions in ecosystems form the basis of many ecological studies, but numbers and names alone are often difficult to interpret. When investigating the feeding relations between organisms, ecologists can use **food web networks** and **heatmaps**, which best present datasets that include a list of predator (consumer) species, prey (resource) species, and interaction strength (OR, biomass and density). Such visual depiction can be done on `RStudio` via versatile R packages that allow colourful, customizable presentations of data, including (but not limited to) `ggraph` and `ggplot2`.

From this tutorial you will learn how to visualize food webs in two formats, **network** and **heat map**, as well as data manipulation required in prior. Both methods of visualisation have its own merits – networks allow easier identification of food chains and trophic levels, while heatmaps focus on displaying interaction strength. 

You can get all of the resources for this tutorial from <a href="https://github.com/EdDataScienceEES/tutorial-keenmustard.git" target="_blank">this GitHub repository</a>. Clone and download the repo as a zip file, then unzip it.

Before you dive into this tutorial, it is recommended you are familiar with the [basic dplyr operations]( https://ourcodingclub.github.io/tutorials/data-manip-intro/ ) and [data visualisation]( https://ourcodingclub.github.io/tutorials/datavis/).

<a name="section1"></a>

## 1. Extract ecological data from external library `cheddar`


To map energy flow or predator-prey interactions in an ecosystem, ecologists often track which species are present, their population density and biomass per capita. We call species, or groups of species involved in the food web ‘nodes’; and links are lines connecting nodes, that indicate a predator-prey relationship. 

`cheddar` is a package specialised for analysis and visualisation of ecological communities in R, with a few built-in datasets. (For more details on the package, visit its [official repository](https://github.com/quicklizard99/cheddar ).) However, in this tutorial, this package will primarily serve as a portal to the `BroadstoneStream` freshwater dataset from Quantiﬁcation and resolution of a complex, size-structured food web by Woodward, Speirs, and Hildrew (2005). 

To start off, create a new R script with a few lines of information at the top and you’re good to go (remember to use hasthags # for all annotations).

```r
# Visualising Food Webs on R
# Your name
# DD/MM/YYYY`

```
Now, let’s install and load libraries of all packages required in this tutorial, and import the dataset from `cheddar`. 

```r
# Install arequired packages (omit if you already have them installed)
install.packages("cheddar") # data and functions for analysing/visualising food web data
install.packages("tidyverse") # includes data wrangling tools such as dplyr, tidyr
install.packages("ggplot2") # a useful graphic display tool
install.packages("igraph") # helps visualise food web network
install.packages("ggraph") # an extension of ggplot2, creates food web heat map

# Load required libraries
library(cheddar)
library(tidyverse) 
library(ggplot2)
library(igraph) 
library(ggraph)

# Obtain the BroadstoneStream dataset from cheddar and save the useful data frames as objects
data("BroadstoneStream")
node_properties <- NPS(BroadstoneStream) # Extract node properties (species data)
trophic_links <- TLPS(BroadstoneStream) # Extract trophic links (prey-predator interactions)
properties <- BroadstoneStream[["properties"]] # Extract properties (unit key)

```
Alternatively, if you don’t wish to install `cheddar`, the data frames (nodes.csv and trophiclinks.csv) are included in [this](https://github.com/EdDataScienceEES/tutorial-keenmustard.git) `Github` repository, which also holds this tutorial’s sample script.   

```r
# ALTERNATIVE: To directly access data without cheddar, instead of ("BroadstoneStream"), use the below code:
node_properties <- read.csv("broadstonestream_data/nodes.csv")   # Extract node properties (species data)
trophic_links <- read.csv("broadstonestream_data/trophic_links.csv")  # Extract trophic links (prey-predator interactions)
properties <- read.csv("broadstonestream_data/properties.csv")  # Extract properties (unit key)

```

There are 3 data frames in total - `trophic_links`,`node properties` and `properties`. `properties` is not required in calculations, but it tells us about the units used. Let’s see what we've got:

```r
# Examine data properties
str(properties)
str(node_properties)
str(trophic_links)
```

`node_properties` shows 37 entries of species, along with their mass (`M`) , density (`N`), and the taxonomic groups they belong to. According to `properties`, `M` (mass) and `N` (density) columns have mg and m^-2 (per square meter) as units respectively.

`trophic_links` includes two columns only, with each row being a predator-prey pair. 


<a name="section2"></a>

## 2. Subset, extract and modify data using dplyr 

We can now move on to tidy the data frames we have just extracted. If we try run some code, we could gain even deeper understanding of which nodes are present, and between which ones should connections exist. 

```r
# Let's view what species do we have exactly!
unique(node_properties$node) 
```
There are some producers (`Algae`) and detritus (`CPOM` and `FPOM`) here! I would assume they are resources. Let's see if they are in `trophic_links$resource`.

```r
unique(trophic_links$resource) 
```
They don't seem to be! If we run another few lines line to find differences...

```r
# Create data frames containing characters in nodes' but not 'resources'; and vice versa
nodes_not_in_resources <- setdiff(unique(node_properties$node), unique(trophic_links$resource))
resources_not_in_nodes <- setdiff(unique(trophic_links$resource), unique(node_properties$node))
# And display the result...
list(Nodes_Not_in_Resources = nodes_not_in_resources,
  Resources_Not_in_Nodes = resources_not_in_nodes)

```

From the code output, we can tell that the producer (`algae`) and detritus (`CPOM` and `FPOM`) are not recorded as resources in trophic links. This implies our food web will focus on trophic levels from primary consumer onwards. Additionally, we also see invertebrates including _Platambus maculatus_ and _Adicella reducta_ not included in prey, implying such organisms are in the top trophic level.

What we still need to know is the **interaction strength** between a predator-prey duo, which, with limited data, can be represented with **biomass flux** instead, estimated by \( I = \frac{M_j \times N_j}{M_i} \) where \( I \) = The interaction strength between predator and prey; \( M_j\) = Mass (or biomass) of the prey species\( N_j\); N_j= Density of the prey species (j) ; \( M_i\): Mass (or biomass) of the predator species (i).

Run the below code (written in our favourite `tidyverse` format) to calculate \( M_j\) * \( N_j\) and \( M_i\) for every node. Please note that at this step, it seems like we are ridiculously assuming each node could be prey and predator simultaneously – even though there are definitely prey-only and predator-only nodes (e.g. `Diptera` and _Platambus maculatus_ we saw from the last step were not found in the list of `resource`) in this ecosystem. But don’t worry, we won’t end up using every value calculated here. At this step we just can’t tell which ones are prey- or predator-only yet since the trophic links are recorded in another data frame. 

```r
# Calculate biomass (M * N) for prey and keep only mass for predators
node_properties <- node_properties %>%
  mutate(
    prey_biomass = M * N,  # Prey biomass includes mass and density
    predator_mass = M      # Predator biomass is just the mass
  ) %>%
  select(node, prey_biomass, predator_mass)  # Keep only necessary columns 
```
Now that we have gotten every node’s prey total biomass and predator biomass, we could assign the values to each corresponding predator-prey pair via joining `node_properties` to `trophic_links` with `dplyr`’s `left_join()`.

```r
# Joining trophic_links with node_properties
trophic_links <- trophic_links %>%
  # Add prey biomass by joining on 'resource' (prey nodes)
  left_join(node_properties %>% select(node, prey_biomass), by = c("resource" = "node")) %>%
  # Add predator mass by joining on 'consumer' (predator nodes)
  left_join(node_properties %>% select(node, predator_mass), by = c("consumer" = "node"))
```
Finally, we can calculate $I$ for each interacting pair (Hint: \( I = \frac{M_j \times N_j}{M_i} \)) only to see the resulting values of \( I \)  are not exactly straightforward. Fortunately, for easier interpretation we can **normalise** $I$, such that it shows how much biomass one prey node contributes to a given predator species, as a **proportion over the total prey biomass flux to that predator species**. For instance, if a predator-prey pair has a normalised value of 0.1, it means this prey species contributes to 10% of the total biomass making up the predator’s diet. 

```r
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
```

<a name="section3"></a>

## 3.	Visualise data as food web network with `ggraph`

<a name="section4"></a>

## 4.	Visualise data as heatmap with `ggplot2`

More text, code and images.

This is the end of the tutorial. Summarise what the student has learned, possibly even with a list of learning outcomes. In this tutorial we learned:

##### - how to generate fake bivariate data
##### - how to create a scatterplot in ggplot2
##### - some of the different plot methods in ggplot2

We can also provide some useful links, include a contact form and a way to send feedback.

For more on `ggplot2`, read the official <a href="https://www.rstudio.com/wp-content/uploads/2015/03/ggplot2-cheatsheet.pdf" target="_blank">ggplot2 cheatsheet</a>.

Everything below this is footer material - text and links that appears at the end of all of your tutorials.

<hr>
<hr>

#### Check out our <a href="https://ourcodingclub.github.io/links/" target="_blank">Useful links</a> page where you can find loads of guides and cheatsheets.

#### If you have any questions about completing this tutorial, please contact us on ourcodingclub@gmail.com

#### <a href="INSERT_SURVEY_LINK" target="_blank">We would love to hear your feedback on the tutorial, whether you did it in the classroom or online!</a>

<ul class="social-icons">
	<li>
		<h3>
			<a href="https://twitter.com/our_codingclub" target="_blank">&nbsp;Follow our coding adventures on Twitter! <i class="fa fa-twitter"></i></a>
		</h3>
	</li>
</ul>

### &nbsp;&nbsp;Subscribe to our mailing list:
<div class="container">
	<div class="block">
        <!-- subscribe form start -->
		<div class="form-group">
			<form action="https://getsimpleform.com/messages?form_api_token=de1ba2f2f947822946fb6e835437ec78" method="post">
			<div class="form-group">
				<input type='text' class="form-control" name='Email' placeholder="Email" required/>
			</div>
			<div>
                        	<button class="btn btn-default" type='submit'>Subscribe</button>
                    	</div>
                	</form>
		</div>
	</div>
</div>
