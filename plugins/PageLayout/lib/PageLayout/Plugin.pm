package PageLayout::Plugin;

use strict;

sub pre_save {
    my ($cb, $app, $obj, $orig) = @_;
    my $blog = $app->blog;
    my $layout = $app->param('template_id');
    $obj->template_id($layout);
    1;
}

sub pre_remove {
    my ($cb, $obj) = @_;
    require MT::Entry;
    require MT::Page;
    my @objs;
    @objs = MT::Entry->load({ template_id => $obj->id });
    foreach (@objs) { $_->template_id(undef); $_->save; }
    @objs = MT::Page->load({ template_id => $obj->id });
    foreach (@objs) { $_->template_id(undef); $_->save; }
    return 1;
}

sub xfrm_edit {
    my ($cb, $app, $param, $tmpl) = @_;
    my $blog = $app->blog;

    my $type = $param->{object_type};
    my $class = $app->model($type);
    if (!$class) {
	MT->log({ blog_id => $blog->id, message => "Invalid type " . $type });
	return 1; # fail gracefully
    }

    my $obj = $class->load($param->{id});
    $param->{template_id} = $obj->template_id;

    my @maps = MT::Template->load( { type => $obj->class eq 'page' ? 'page' : 'individual',
				     blog_id => $blog->id, } );	
    return 1 if ($#maps == 0);
    my $opts;
    foreach (@maps) {
	my $selected = ($obj->template_id == $_->id);
	$opts .= '<option value="'.$_->id.'"'.($selected ? ' selected' : '').'>'.$_->name."</option>\n";
    }
    my $setting = $tmpl->createElement('app:setting', { 
	id => 'template_id', label => $obj->class_label . " Template" });
    $setting->innerHTML('<select name="template_id">'.$opts.'</select>');
    $tmpl->insertAfter($setting,$tmpl->getElementById('authored_on'));
}

1;
