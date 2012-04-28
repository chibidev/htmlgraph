#!/usr/bin/perl
use strict;

#----------------------------------------------------
#  Version : 1.0
#  Date    : 15 February 2009
#  Homepage: http://www.burlaca.com/2009/02/html2gdl/
#  Author  : Oleg Burlaca (email: oleg@burlaca.com)
#----------------------------------------------------
#
#  Usage:
#  
#  html2gdl.pl [OPTIONS]
#      --file=html_filename
#
#      --url=web_page_url
#
#      --graph=output_gdl_filename
#    
#      --engine=[aiSee,GraphViz]        default: aiSee
#
#      --layout=GDL_layout_algorithm   default: forcedir
#			 other layouts: minbackward, tree, ...
#			 http://www.aisee.com/manual/unix/44list.htm#layoutalgorithm
#
#      --attraction=int    default: 70
#
#      --repulsion=int	   default: 40
#
#      --show-labels=[0,1,2]   default: 0
#			0: no labels
#			1: nodes are labeled with their tag names: 'p', 'span'
#			2: css ID and class will be added to the tag: 'div#header.red'
#
#      --debug=[0,1]  default=0
#                        if --debug=1, an hierarchical list of tags will be displayed
#                        the numbers in parantheses denotes the graph edge: (id1 -> id2)
#
#      --max-level=int default: 0
#                        the tree will display tags up to --max-level deepness
#
#      --priority-factor=float   default: 0
#                        for --engine=aiSee
#			 edge.priority = int(priority-factor * node.level)
#                        an excerpt from http://www.aisee.com/manual/unix/46list.htm#priority
#			 the edges can be imagined as rubberbands pulling a node to its position. 
#			 The priority of an edge corresponds to the strength of the imaginary rubberband.
#
#      --edge-len-min=float    default: 0.2
#      --edge-len-max=float    default: 0.9
#                       for --engine=GraphViz
#			edge.len = [max .. min] depending on the level, 
#                       starting with --edge-len-max-level  edge.len=edge_len_min
#
#      --edge-len-max-level=7
# 			the length of edges for below  nodes will be --edge-len-min
#
#      --ignore-tags=tag_list
#                        these and descendant tags will be white colored 
#                        example: --ignore-tags='table,form'
#
#      --fold-tags=tag_list
#                        descendant tags will not be displayed,
#			 although the tag itself will be visible
#
#      --remove-tags=tag_list
#                        tags and their descendants will not be displayed
#
#      --flatten-tags=tag_list
#			 tags are removed but descendants will be linked to the ancestors
#			 of the removed tags
#			 Note: the tag '_text_tags' represents a group of tags, see details below
#
#      --ignore-tags-sl, --fold-tags-sl, --remove-tags-sl, --flatten-tags-sl = int  default: 0
#			these params indicates the starting level (note the -sl suffix)
#			from which ingoring, folding, removing and flattening has effect
#
#      --ignore-levels='L1 - L2'    default: ''
#                        tags at levels L1 to L2 will be white colored
#                        example: --ignore-levels='5 - 10'
#
#      --node-color=[tag,level,size]   default=tag
#			 tag   - color groups defined in $colorMap are used (see below)
#			 level - color gradation 
#			 size  - 
#
#      --border-color=int    default=7 (darkgrey)
#			 specify --border-color=node 
#			 if you want the border of the node  to have the same color as the node
#
#
#      --color-gradient='r1,g1,b1 - r2,g2,b2'  default='55,52,20 - 247,234,91'
#			 if '--node-color' is 'level' or 'size', 
#                        a gradual colorMap is built. 
#                        The number of gradations is the maximum tree level
#
#      --color-gradient-steps=int    default: 7
#			 the number of colors used when --node-color=[level,size]
#
#      --node-radius=[fixed,level,size]     default=fixed
#                        fixed - all nodes have a fixed radius
#                        level - the radius is decreasing with node level
#                        size  - the radius depends on the descendants overall size
#                                i.e. content size (just text without html tags)
#                                Note1: Text under 'script' or 'style' elements is ignored
#                                       when calculating size
#                                Note2: leading and trailing whitespace is deleted,
#                                       and any internal whitespace is collapsed.
#
#      --radius-gradient='Rmin - Rmax'    default='10 - 100'
#			 the minimum and maximum node radius.
#	
#      --radius-gradient-steps=int  default=7
#
#      --radius-size=R  default=25 for aiSee, 0.1 for GraphViz
#			 the radius of the nodes when '--node-radius=fixed'
#
#      --graph-title=string
#			 if no title is specified, the URL or FILE will be used
#
#      A note on tag_list:
#      By specifying '_text_tags' in the 'tag_list', a whole group of tags
#      you can specify '_text_tags' in 'tag_list'.
#      (This applies to --fold-tags, --ignore-tags, --remove-tags, --flatten-tags)
#      '_text_tags' denotes a group of tags 'p, i, b, strong, etc.'
#      these tags may clutter a big html graph, that is why the '_text_tags' group was introduced
#
#      info about text tags:
#      http://www.w3.org/TR/REC-html40/struct/text.html
#      (Remark: the list of html2gdl text elements is larger)
#
#
#  Examples:
#  
#  html2gdl.pl --url=http://www.aisee.com/  --exclude-tags='br, p' --graph=graph.gdl
#
#
#----------------------------------------------------------------------
#
#  CONFIGURATION OPTIONS 
#
our $cfg = {
    'debug'				=> 0,
    'engine'				=> 'aiSee',
    'show-labels'			=> 0,
    'layout'				=> 'forcedir',
    'attraction'			=> 70,
    'repulsion'				=> 40,
    'priority-factor'			=> 0,
    'edge-len-min'			=> 0.15,
    'edge-len-max'			=> 0.8,
    'edge-len-max-level'		=> 9,
    'ignore-levels'			=> '',
    'fold-tags'				=> '',
    'remove-tags'			=> '',
    'node-radius'			=> 'fixed',
    'node-color'    			=> 'tag',
    'color-gradient' 			=> '55,52,20 - 247,234,91',    
    'radius-gradient'			=> '10 - 100',
    'radius-gradient-steps' 		=> 7,
    'radius-size'			=> 30,
    'color-gradient-steps' 		=> 7,

    'border-color' 			=> 7, # darkgrey (node border color)

    'text-tags' 			=> 'p,br,blockquote,q,sub,sup,pre,ins,del,big,i,s,b,u,small,strike,tt,em,strong,dfn,code,samp,kbd,var,cite,abbr,acronym,span,font',
    
    'flatten-tags'			=> '',
    'remove-tags'			=> '',
    'fold-tags'				=> '',
    'ignore-tags'			=> '',
    'max-level'				=> 0,

    'ignore-tags-sl'			=> 0,
    'fold-tags-sl'			=> 0,
    'remove-tags-sl'			=> 0,
    'flatten-tags-sl'			=> 0,
    
    'graph-title'			=> '',
    
    '_gdl_color_start_idx' => 33,  # GDL user defined colors index
				   # aiSee has a color map of 256 colors of which 254 can be used. 
				   # The first 32 colors (index 0 . 31) of
				   # the color map are the default colors.
};

#  specify the tags and their colors (for aiSee and/or GraphViz)


#---  aiSee --------------------------------------------------------------------------------------
#  refer to the aiSee manual (GDL Language / Color Section) 
#  for the list of default colors. 
#
#  You can define your own colors, but you'll have to add 
#  color definitions yourself in graphHeader in the code (see &getGraphHeader_aiSee() function)
#
$cfg->{colorMap_aiSee} = { 
    '_ignore'		=> 0,    # white
    '_default'          => 15,   # lightgrey
    '_root'		=> 31,   # black (the root node)
    '_empty'            => 0,    # white  (nodes with size==0)    
    '_edge_color'       => 15,   # lightgrey    
    'a'                 => 1,    # blue
    'div'               => 3,    # green
    'img'               => 5,    # magenta

    '_text_tag'    	=> 7,    # darkgrey
    
    # list: yellowgreen
    'ul, ol, li, dl, dt, dd, dir, menu' => 25,
    
    # heading: cyan
    'h1, h2, h3, h4, h5, h6' => 6,

    # table: orange
    'table, thead, tbody, caption, col, colgroup, th, tr, td, tfoot'   => 29,

    # form: yellow
    'form, input, select, optgroup, textarea, fieldset, legend, option, button, label' => 4,
    
    # external content
    'applet, script, object, iframe, frame, frameset, link, style' => 2,   # red
};

#----- GraphViz ---------------------------------------------------------------------------------
$cfg->{colorMap_GraphViz} = {
    '_ignore'           => '#FFFFFF',    # white
    '_default'          => '#AAAAAA',    # lightgrey
    '_root'		=> '#000000',    # black
    '_empty'		=> '#FFFFFF',	 # white  (nodes with size==0)
    '_edge_color'       => '#AAAAAA',    # lightgrey
    'a'                 => '#0000FF',    # blue
    'div'               => '#00FF00',    # green
    'img'               => '#FF00FF',    # magenta
    
    '_text_tag'         => '#555555',    # darkgrey
    
    # list: khaki
    'ul, ol, li, dl, dt, dd, dir, menu' => '#F0E68C',
            
    # heading: cyan
    'h1, h2, h3, h4, h5, h6' => '#00FFFF',

    # table: orange
    'table, thead, tbody, caption, col, colgroup, th, tr, td, tfoot'   => '#FFA500',
        
    # form: yellow
    'form, input, select, optgroup, textarea, fieldset, legend, option, button, label' => '#FFFF00',                        

    # external content
    'applet, script, object, iframe, frame, frameset, link, style' => '#FF0000',   # red
};

#---------------------------------------------------------------------------
#
#  END OF CONFIGURATION SECTION
#
#  Modify the code below if you know what you are doing :)
#
#---------------------------------------------------------------------------


use LWP::Simple ();
use HTML::TreeBuilder ();

if ($#ARGV == -1) {
    print "Usage: html2gdl.pl [OPTIONS]\n";
    print "Read the instructions at the beginning of the script\n";
    exit;
}
        
our $params = {};
if (! &parseParams()) {
    print "check your params! \n";
    exit;
}        

our $data = {graphGDL => '', totalNodes => 1,  nodes => {}, edges => {}, tagHits => {}, maxNodeSize => 1,};

&init();


my $tree = HTML::TreeBuilder->new;
if ($params->{file}) {
    $tree->parse_file($params->{file}) || die "Can't parse file!\n Error: ", $!;
} else {
    $tree->parse($params->{_html});
    $tree->eof();
}

# add the root node: 'html'
$data->{nodes}{1} = {id => 1, tag => 'html', level => 0, size => length($tree->as_trimmed_text())};

&traverseNode(1, $tree, 1);
$tree = $tree->delete;   # release memory


my $graph = '';

if ($cfg->{engine} eq 'GraphViz') {
    $graph = &getGraphHeader_GraphViz() . &getOrderedGraph_GraphViz() . '}';	
} else {
    # $data->{graphGDL} = ;
    $graph = &getGraphHeader_aiSee() . &getOrderedGraph_aiSee() . '}';	
}



# print "\n", &getTagHits(), "\n";

#  write graph to --graph-file;
open (MYFILE, ">$params->{'graph'}");
print MYFILE $graph;
close (MYFILE); 






#-----------------------------------------------------------------------------
sub setGraphVizDefaults {
    $cfg->{'border-color'} = '#555555';
    $cfg->{'radius-size'} = 0.12;
    $cfg->{'radius-gradient'} = '0.05 - 0.5';
}
#-----------------------------------------------------------------------------                    
sub init {
    if ($params->{engine} eq 'GraphViz') { &setGraphVizDefaults() }
    
    # override default values with command line params
    foreach my $k (keys %$cfg) {
	$cfg->{$k} = $params->{$k} if exists $params->{$k};
    }
    
    if ($cfg->{engine} eq 'aiSee') {
        &populateTagColors($cfg->{colorMap_aiSee});
    } else {
	&populateTagColors($cfg->{colorMap_GraphViz});
    }
    
    $cfg->{'graph-title'} ||= $params->{url} || $params->{file};
    
    $cfg->{_textTags} = {};
    &explodeTagList($cfg->{_textTags}, $cfg->{'text-tags'}, 0);
    
    $cfg->{_flattenTags} = {};
    $cfg->{_removeTags} = {};
    $cfg->{_foldTags} = {};
    $cfg->{_ignoreTags} = {};
    
    if ($cfg->{'flatten-tags'}) { &explodeTagList($cfg->{_flattenTags}, $cfg->{'flatten-tags'}, 0) }
    if ($cfg->{'remove-tags'}) { &explodeTagList($cfg->{_removeTags}, $cfg->{'remove-tags'}, 0) }
    if ($cfg->{'fold-tags'}) { &explodeTagList($cfg->{_foldTags}, $cfg->{'fold-tags'}, 0) }
    if ($cfg->{'ignore-tags'}) { &explodeTagList($cfg->{_ignoreTags}, $cfg->{'ignore-tags'}, 0) }
    
    ($cfg->{'radius-gradient-min'}, $cfg->{'radius-gradient-max'}) = split(/ \- /, $cfg->{'radius-gradient'});
    if ($cfg->{'ignore-levels'}) { ($cfg->{_ignoreLevelMin}, $cfg->{_ignoreLevelMax}) = split(/ \- /, $cfg->{'ignore-levels'}) }
}
#-----------------------------------------------------------------------------
sub traverseNode {
    my ($id, $node, $level) = @_;
    
    #  The tree will be displayed up to max-level
    return if ($cfg->{'max-level'} and $level > $cfg->{'max-level'});
    
    foreach my $child ($node->content_list()) {
        #  check if $node is not a simple string,
        #  I thought $node->content_list() should return '0' 
        #  for a node that doesn't have sub-tags, but it is not
        next if ! ref $child;

	#  get the tag name
        my $tag = $child->tag;
                
        # check if the tag should be removed
        next if ($cfg->{'remove-tags'} and $level >= $cfg->{'remove-tags-sl'} and
                (exists $cfg->{_removeTags}{$tag} or 
                (exists $cfg->{_removeTags}{_text_tags} and exists $cfg->{_textTags}{$tag})));

	if ($cfg->{'flatten-tags'} and $level >= $cfg->{'flatten-tags-sl'} and 
	(exists $cfg->{_flattenTags}{$tag} or 
	(exists $cfg->{_flattenTags}{_text_tags} and exists $cfg->{_textTags}{$tag})) ) {
	    &traverseNode($id, $child, $level);
	    next;
	}
        
        #  $total is the last assigned ID for graph nodes
        $data->{totalNodes}++;
        my $total = $data->{totalNodes};
        my $nodeDef = {id => $total, level => $level, tag => $tag, 
    		       css_id => $child->attr('id'), css_class => $child->attr('class')};
        
	#  show html skeleton if debug=1
        my $t = $tag;
	$t .= '#' . $nodeDef->{css_id} if $nodeDef->{css_id};
        $t .= '.' . $nodeDef->{css_class} if $nodeDef->{css_class};
        $t .= "\n"; # " ($id -> $total)\n"
                
        print '   ' x $level, $t  if $cfg->{debug};
        
        # calculate the size of the node (descendants text length)
        if ($cfg->{'node-radius'} eq 'size' or $cfg->{'node-color'} eq 'size') {
    	    $nodeDef->{size} = length($child->as_trimmed_text());
    	    $data->{maxNodeSize} = $nodeDef->{size} if ($data->{maxNodeSize} < $nodeDef->{size});
        }
        $data->{maxNodeLevel} = $nodeDef->{level} if ($data->{maxNodeLevel} < $nodeDef->{level});
	$data->{nodes}{$total} = $nodeDef;

	# !!! if node color will depend on its ancestor, the color will be calculated here
	
        my $edgeId = $id*10000 + $total; # sprintf("%04d", $id, $total)
        $data->{edges}{$edgeId} = {source => $id, target => $total};
        
        #  --engine=aiSee
        if ($cfg->{'priority-factor'}) {
    	    my $priority = int($cfg->{'priority-factor'} * $level);
    	    $priority = 1 if $priority < 1;
    	    $data->{edges}{$edgeId}{priority} = $priority;
    	}

        #  --engine=GraphViz
        if ($cfg->{engine} eq 'GraphViz' and ($cfg->{'edge-len-min'} != $cfg->{'edge-len-max'})) {
            my $len = $cfg->{'edge-len-min'} + 
                      ($cfg->{'edge-len-max-level'} - $level + 1)*($cfg->{'edge-len-max'} - $cfg->{'edge-len-min'})/$cfg->{'edge-len-max-level'};
        
    	    $len = sprintf("%.3f", $len);
    	    $len = $cfg->{'edge-len-min'} if $len < $cfg->{'edge-len-min'};
	    $data->{edges}{$edgeId}{len} = $len;
        }
        
        
        next if ($cfg->{'fold-tags'} and $level >= $cfg->{'fold-tags-sl'} and
    		(exists $cfg->{_foldTags}{$tag} or 
    		(exists $cfg->{_foldTags}{_text_tags} and exists $cfg->{_foldTags}{$tag})));
        
        #  go down one level and add child nodes to the graph
        &traverseNode($total, $child, $level+1); 
    }
}
#-----------------------------------------------------------------------------------
sub explodeTagList {
    my ($h, $tags, $color) = @_;
    $tags = lc($tags);
    foreach my $tag (split(/,/, $tags)) { $tag =~ s/^\s+//; $tag =~ s/\s+$//; $h->{$tag} = $color }
}
#-----------------------------------------------------------------------------------
#  generate the graph colorMap
# 
sub populateTagColors {
    my ($colorMap) = @_;
    $cfg->{_tagColor} = {};
    while (my ($k, $v) = each %$colorMap) {
	explodeTagList($cfg->{_tagColor}, $k, $v);
    }
}
#-----------------------------------------------------------------------------------
sub parseParams {
    foreach my $p (@ARGV) {
	my ($k, $v) = split (/=/, $p, 2);
	$k =~ s/^\-\-//;
	$params->{$k} = $v;
    }
    
    # print Dumper($cfg);
    
    if (! $params->{file} and ! $params->{url}) {
	print "Specify either a --file= OR --url=  parameter\n";
	return 0;
    }
    
    #  check if an URL is specified
    $params->{_html} = LWP::Simple::get($params->{url}) if $params->{url};

    return 1;    
}
#-----------------------------------------------------------------------------------
sub getNodeAttr {
    my ($node) = @_;
    my $tag = $node->{tag};
    my $h = {};
    my $c = $cfg->{_tagColor}{_default};
    my $borderStyle = undef;
    
    # do not color the node if:
    #     - it's in the ignore-tags list
    #     - is a text tag  and  ignore-text-tags=1
    #     - the level of the node is in the [ignoreLevelMin, ignoreLevelMax] range
    #
    if (($cfg->{'ignore-tags'} and exists $cfg->{_ignoreTags}{$tag})
        or
        (exists $cfg->{_ignoreTags}{_text_tags} and exists $cfg->{_textTags}{$tag})
        or
        ($cfg->{'ignore-levels'} and
            ($cfg->{_ignoreLevelMin} <= $node->{level} and 
            $node->{level} <= $cfg->{_ignoreLevelMax}))
       )
    {
        $c = $cfg->{_tagColor}{_ignore};
        $borderStyle = 'dotted';
    } 
           
    # node-color=tag
    elsif ($cfg->{'node-color'} eq 'tag') {
        if ($tag eq 'html') {
	    $c = $cfg->{_tagColor}{_root};
        } elsif (exists $cfg->{_textTags}{$tag}) {
    	    $c = $cfg->{_tagColor}{_text_tag};
        } elsif (exists $cfg->{_tagColor}{$tag}) {
	    $c = $cfg->{_tagColor}{$tag};
        }
    } elsif ($cfg->{'node-color'} eq 'level') {
	$c = $cfg->{_gdl_color_start_idx} + 
	     int($cfg->{'color-gradient-steps'} * $node->{level} / $data->{maxNodeLevel});
	if ($cfg->{engine} eq 'GraphViz') {
    		$c = $cfg->{_gradientColors}{$c};
            }
    } elsif ($cfg->{'node-color'} eq 'size') {
	$c = $cfg->{_gdl_color_start_idx} +
	     int($cfg->{'color-gradient-steps'} * (1 - $node->{size} / $data->{maxNodeSize}));

        
        if ($cfg->{engine} eq 'GraphViz') {
    	    $c = $cfg->{_gradientColors}{$c};
        }
        
        # root is black
        # empty nodes are white
        if ($node->{level} == 0) {
    	    $c = $cfg->{_tagColor}{_root};
        } elsif ($node->{size} == 0) {
    	    $c = $cfg->{_tagColor}{_empty};
        }
    }

    if ($cfg->{'node-radius'} eq 'level' or $cfg->{'node-radius'} eq 'size') {
	my $minR = $cfg->{'radius-gradient-min'};
	my $maxR = $cfg->{'radius-gradient-max'};
	my $k = $cfg->{'radius-gradient-steps'};
	my $radius;
	if ($cfg->{'node-radius'} eq 'size') {
	    $radius = $minR + (($maxR - $minR) * $node->{size} / $data->{maxNodeSize});
	} else {
	    $radius = $minR + (($k - $node->{level}) * ($maxR - $minR) / $k);
	}
	$radius = $minR if $radius < $minR;
	$h->{radius} = sprintf("%.3f", $radius);
    } 
    
	
    $h->{color} = $c if ($c ne $cfg->{_tagColor}{_default});
    $h->{borderColor} = $h->{color} if (exists $h->{color} and $cfg->{'border-color'} eq 'node');
    $h->{borderStyle} = $borderStyle if defined $borderStyle;
    
    return $h;
}
#-----------------------------------------------------------------------------------
sub getOrderedGraph_aiSee {
    my $t = '';
    
    # dump nodes
    my $h = $data->{nodes};
    foreach my $k (sort {$a <=> $b} keys %$h) {
	my $node = $h->{$k};

	my $label = '';
	if ($cfg->{'show-labels'} > 0) { $label = $node->{tag} }
	if ($cfg->{'show-labels'} == 2) {
	    $label .= '#' . $node->{css_id} if $node->{css_id};
	    $label .= '.' . $node->{css_class} if $node->{css_class};
	}
	
	$t .= "node: {title:\"$node->{id}\" label:\"$label\"";

	#  for stats
	$data->{tagHits}{ $node->{tag} }++;
	
	my $a = &getNodeAttr($node);
	
        $t .= " color: $a->{color}" if exists $a->{color};
        $t .= " bordercolor: $a->{borderColor}" if (exists $a->{borderColor});
	$t .= " borderstyle: $a->{borderStyle}" if (exists $a->{borderStyle});
	$t .= " width: $a->{radius} height: $a->{radius}" if (exists $a->{radius});

        $t .= "}\n";
    }
    
    # dump edges
    $h = $data->{edges};
    foreach my $k (sort {$a <=> $b} keys %$h) {
        my $edge = $h->{$k};
        $t .= "edge: {source: \"$edge->{source}\" target: \"$edge->{target}\"";
        $t .= " priority: $edge->{priority}" if exists $edge->{priority};
        $t .= "}\n";
    }
    return $t;
}
#-----------------------------------------------------------------------------------
sub getOrderedGraph_GraphViz {
    my $t = '';
    
    # dump nodes
    my $h = $data->{nodes};
    foreach my $k (sort {$a <=> $b} keys %$h) {
	my $node = $h->{$k};

        my $label = '';
        if ($cfg->{'show-labels'} > 0) { $label = $node->{tag} }
        if ($cfg->{'show-labels'} == 2) {
    	    $label .= '#' . $node->{css_id} if $node->{css_id};
    	    $label .= '.' . $node->{css_class} if $node->{css_class};
	}
		
	$t .= "node [";

	#  for stats
	$data->{tagHits}{ $node->{tag} }++;
		
	my $a = &getNodeAttr($node);
	
	my $attr = "label=\"$label\",";
	$a->{color} ||= $cfg->{_tagColor}{_default};
	$attr .= " fillcolor=\"$a->{color}\"," if exists $a->{color};
	$attr .= " color=\"$a->{borderColor}\"," if (exists $a->{borderColor});
	#$attr .= " borderstyle: $a->{borderStyle}" if (exists $a->{borderStyle});
	$attr .= " width=$a->{radius}, height=$a->{radius}," if (exists $a->{radius});
	chop($attr);
		
	$t .= $attr . '] n' . $node->{id} . ";\n";
    }
    
    # dump edges
    $h = $data->{edges};
    foreach my $k (sort {$a <=> $b} keys %$h) {
        my $edge = $h->{$k};
        $t .= " n$edge->{source} -- n$edge->{target}";
        my $attr = '';
        $attr .= "len=$edge->{len}," if exists $edge->{len};
        # $attr .= "weight=" . sprintf("%.3f", $edge->{priority}) . ',' if $edge->{priority};
        
        chop($attr);
        if ($attr) { $attr = ' [' . $attr . ']' }
        
        $t .= "$attr;\n";
    }
    return $t;
}
#-----------------------------------------------------------------------------------


sub getTagHits {
    my $tagHits = $data->{tagHits};

    my $t = "Top 10 tags:\n";
    my $i = 0;
    foreach my $tag (sort {$tagHits->{$b} <=> $tagHits->{$a}} keys %$tagHits) {
	$t .= "$tag\t: $tagHits->{$tag}\n";
	$i++;
	last if $i == 10;
    }
    return $t;
}

#-----------------------------------------------------------------------------------
sub getGradientColors {
    my ($c1, $c2) = split(/ \- /, $cfg->{'color-gradient'});
    
    my @rgb1 = split(/,/, $c1);    # darkest color
    my @rgb2 = split(/,/, $c2);    # lightest color
    
    my $Rdiff = $rgb2[0] - $rgb1[0];
    my $Gdiff = $rgb2[1] - $rgb1[1];
    my $Bdiff = $rgb2[2] - $rgb1[2];

    my $t = '';
    
    my $steps = $cfg->{'color-gradient-steps'};
    
    $cfg->{_gradientColors} = {};
    for (my $i=0; $i < $steps+1; $i++)
    {
	my $colorIndex = 33 + $i;
	my $R = int($rgb1[0]+$i*$Rdiff/$steps);
        my $G = int($rgb1[1]+$i*$Gdiff/$steps);
        my $B = int($rgb1[2]+$i*$Bdiff/$steps);
        $t .=  "colorentry $colorIndex: $R $G $B\n";

        # for engine=GraphViz
        $cfg->{_gradientColors}{$colorIndex} = '#' .  sprintf("%1x%1x%1x", $R, $G, $B);
    }

    return $t;
}

#-----------------------------------------------------------------------------------
#  The header of the graph
#  engine=aiSee
#
sub getGraphHeader_aiSee {
my $t = <<_GRAPH_;
graph: {title: "$cfg->{'graph-title'}"
        layoutalgorithm : $cfg->{layout}
        scaling		: maxspect
        gravity		: 0.0         
	attraction      : $cfg->{attraction}
        repulsion       : $cfg->{repulsion}
        tempmin		: 30
        arrowmode       : free        
        magnetic_field1 : polar               
        magnetic_field2 : no   
        node.width	:  $cfg->{'radius-size'}
	node.height	: $cfg->{'radius-size'}
	node.shape	:  circle
	node.color	: $cfg->{_tagColor}{_default}
	node.fontname	:"helvR10"
	edge.fontname	:"helvR08"
	edge.color	: $cfg->{_tagColor}{_edge_color}
_GRAPH_

    $t .= 'node.bordercolor: ';
    $t .= $cfg->{'border-color'} eq 'node' ? $cfg->{_tagColor}{_default}
					   : $cfg->{'border-color'};
    $t .= "\n";	

    $t .= &getGradientColors() if ($cfg->{'node-color'} ne 'tag');

    return $t;
}

#-----------------------------------------------------------------------------------
#  The header of the graph
#  engine=GraphViz
#
sub getGraphHeader_GraphViz {

&getGradientColors() if ($cfg->{'node-color'} ne 'tag');

my $t = <<_GRAPH_;
graph HMTL {
nodesep=0.1;
node[shape=plaintext, fontcolor="#555555", fontname=Helvetica, fontsize=7, style=filled, fillcollor="$cfg->{_tagColor}{_default}", color="$cfg->{'border-color'}", width=$cfg->{'radius-size'}, height=$cfg->{'radius-size'}];
edge[color="$cfg->{_tagColor}{_edge_color}"];

_GRAPH_

return $t;
}
