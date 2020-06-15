;(function($, window, document, undefined) {
	var $win = $(window);
	var $doc = $(document);

	$doc.ready(function() {
		setInterval(function(){ $('[data-toggle="popover"]').popover(); }, 1000);

		$('.datepicker').datepicker({
			format: 'mm/dd/yyyy',
			startDate: '-3d'
		});

		$('.form-certifications').on('change', 'input:file', function(e){
			var $this = $(this);
			var fileName = $this.val();

			$this.siblings('.form__file-overlay').addClass('hidden');
			$this.siblings(".file-delete").removeClass('hidden');

			$this.siblings(".filename").html(fileName);
		});

		$('.form-certifications').on('click', '.file-delete', function(e){
			e.preventDefault();

			var $this = $(this);

			$this.addClass('hidden');
			$this.siblings('.form__file-overlay').removeClass('hidden');
			$this.siblings('input:file').val('');
		});

		$('.header .container').append('<a href="#" class="btn-nav"></a>')

		$('.btn-nav').on('click', function(e){ 
			e.preventDefault(); 

			$('.wrapper').toggleClass('expanded');
		})
	});

})(jQuery, window, document);
